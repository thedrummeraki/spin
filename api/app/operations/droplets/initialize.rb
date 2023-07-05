module Droplets
  class Initialize < ::Base
    property! :droplet, accepts: Droplet

    def execute
      init_droplet!
    end

    private

    def init_droplet!
      return false unless droplet.exists_on_digitalocean?

      wait_for_droplet_to_be_available(every: 2)
      execute_initialization_commands(droplet.public_ip)

      true
    end

    def wait_for_droplet_to_be_available(every:)
      loop do
        status = client.droplets.find(id: droplet.digitalocean_instance.id).status
        break if status == 'active'

        sleep(every)
      end
    end

    def execute_initialization_commands(public_ip)
      Net::SSH.start(public_ip, 'root') do |ssh|
        commands.each do |command|
          ssh.exec!(command)
        end
      end
    rescue Errno::ECONNREFUSED
      Rails.logger.warn("Address #{public_ip} not available yet, retrying in 5 seconds...")
      sleep(5)
      retry
    end

    def commands
      [
        'apt-get update && apt-install -y build-essential && apt-get autoremove -y',
        'curl -sfL https://get.k3s.io | sh -',
        'k3s kubectl get node',
      ]
    end
  end
end
