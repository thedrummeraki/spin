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
        existing_ssh_key = client.ssh_keys.all.find do |ssh_key|
          ssh_key.public_key == public_key
        end

        if existing_ssh_key
          Rails.logger.info("SSH key was already uploaded on DigitalOcean.")
          existing_ssh_key
        else
          client.ssh_keys.create(instance)
        end
      end
  
      def generate_ssh_key_on_host!
        private_key_filename = "#{ENV.fetch('HOME')}/.ssh/id_rsa"
        public_key_filename = "#{private_key_filename}.pub"
        
        if File.exist?(private_key_filename)
          Rails.logger.info("SSH key on host was already generated.")
        else
          Rails.logger.info("SSH key doesn't exist. Generating on host...")
          command = "ssh-keygen -f #{private_key_filename} -N '' <<< y"
          bash_command = "bash -c \"#{command}\""
          
          # Execute the command
          %x(#{bash_command})
        end
  
        File.read(public_key_filename)
      end

      def droplet_options
        manifest = Projects::Github::Repos::Manifest.perform(project_slug: project_slug)
        config = manifest.dig(:droplet, :config)
        { name: qualified_name }.merge(config)
      end
    end
  end    
end

