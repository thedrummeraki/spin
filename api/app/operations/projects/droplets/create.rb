module Projects
  module Droplets
    class Create < ::Base
      property! :project_slug, accepts: String
  
      def execute
        ensure_exists_on_github!

        droplet = create_droplet!
        initialize_droplet_later(droplet)

        droplet
      rescue => e
        Rails.logger.error("Unexpected error while creating a droplet: #{e}")
      end
  
      private

      def ensure_exists_on_github!
        return if Projects::Github::Exists.perform(project_slug: project_slug)
  
        raise Errors::NotFound, project_slug
      end
  
      def create_droplet!
        ssh_key = create_ssh_key!
        make_digitalocean_droplet_instance!(ssh_key)
      end
  
      def initialize_droplet_later(droplet)
        InitializeDropletJob.perform_later(project_slug, droplet.id)
      end
  
      def make_digitalocean_droplet_instance!(ssh_key)
        Rails.logger.info("Creating droplet on DigitalOcean...")
        options = droplet_options.merge({ssh_keys: [ssh_key.id]})
        instance = DropletKit::Droplet.new(**options)
  
        client.droplets.create(instance)
      end
  
      def create_ssh_key!
        public_key = generate_ssh_key_on_host!
  
        instance = DropletKit::SSHKey.new(
          name: "#{qualified_name}-auto-generated",
          public_key: public_key,
        )
  
        Rails.logger.info("Uploading generated SSH key to DigitalOcean...")
        client.ssh_keys.create(instance)
      end
  
      def generate_ssh_key_on_host!
        Rails.logger.info("Generating SSH key on host...")
        private_key_filename = "#{ENV.fetch('HOME')}/.ssh/id_rsa"
        command = "ssh-keygen -f #{private_key_filename} -N '' <<< y"
        bash_command = "bash -c \"#{command}\""
        
        # Execute the command
        %x(#{bash_command})
  
        public_key_filename = "#{private_key_filename}.pub"
        File.read(public_key_filename)
      end

      def qualified_name
        QualifiedName.perform(project_slug: project_slug)
      end

      def droplet_options
        manifest = Projects::Github::Repos::Manifest.perform(project_slug: project_slug)
        config = manifest.dig(:droplet, :config)
        { name: qualified_name }.merge(config)
      end
    end
  end    
end

