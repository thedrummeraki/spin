module Droplets
  class Create < ::Base
    property! :project_request, accepts: ProjectRequest

    def execute
      droplet = create_droplet!
      droplet.update!(status: 'created')
      initialize_droplet_later(droplet)
      
      droplet
    rescue => e
      Rails.logger.error("Unexpected error while creating a droplet: #{e}")
      project_request.droplet&.update(status: 'failed')
    end

    private

    def create_droplet!
      droplet = project_request.build_droplet

      ssh_key = create_ssh_key!
      created_instance = make_digitalocean_droplet_instance!(ssh_key)

      droplet.digitalocean_id = created_instance.id
      droplet.ssh_keys << ssh_key
      droplet.save
      droplet
    end

    def initialize_droplet_later(droplet)
      InitializeDropletJob.perform_later(droplet.id)
    end

    def make_digitalocean_droplet_instance!(ssh_key)
      Rails.logger.info("Creating droplet on DigitalOcean...")
      instance = DropletKit::Droplet.new(
        name: "#{project_request.sanitized_project_slug}-#{hashed_email}",
        region: "tor1",
        image: "ubuntu-22-04-x64",
        size: "s-1vcpu-2gb",
        ssh_keys: [ssh_key.digitalocean_id],
      )

      client.droplets.create(instance)
    end

    def create_ssh_key!
      public_key = generate_ssh_key_on_host!

      instance = DropletKit::SSHKey.new(
        name: "#{project_request.sanitized_project_slug}-auto-generated",
        public_key: public_key,
      )

      Rails.logger.info("Uploading generated SSH key to DigitalOcean...")
      instance = client.ssh_keys.create(instance)
      SshKey.create(digitalocean_id: instance.id, public_key: public_key)
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

    def hashed_email
      Digest::SHA256.hexdigest(project_request.email).first(10)
    end
  end
end
