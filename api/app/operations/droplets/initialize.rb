module Droplets
  class Initialize < ::Base
    property! :droplet, accepts: Droplet

    def execute
      init_droplet!
    end

    private

    def init_droplet!
      return unless droplet.exists_on_digitalocean?

      wait_for_droplet_to_be_available(every: 2)
      execute_initialization_commands(droplet.public_ip)

      droplet.app_host
    end

    def wait_for_droplet_to_be_available(every:)
      Rails.logger.info("Waiting for droplet to be available...")
      loop do
        status = client.droplets.find(id: droplet.digitalocean_instance.id).status
        break if status == 'active'

        sleep(every)
      end
    end

    def execute_initialization_commands(public_ip)
      Net::SSH.start(public_ip, 'root') do |ssh|
        setup_commands.each do |command, with_output|
          execute_ssh_command!(ssh, command, with_output)
        end

        check_containers_all_running!(ssh, wait: 10)
      end
    rescue Errno::ECONNREFUSED
      Rails.logger.warn("Address #{public_ip} not available yet, retrying in 5 seconds...")
      sleep(5)
      retry
    end

    def execute_ssh_command!(ssh, command, with_output)
      Rails.logger.info("Executing command: #{command}")
      output = ssh.exec!(command)
      return unless with_output

      puts(output)
      output
    end

    def check_containers_all_running!(ssh, wait:)
      max_retry = 20
      retry_count = 0

      loop do
        Rails.logger.info("Executing command: #{k8s_status_command}")
        output = ssh.exec!(k8s_status_command)
        statuses = output.split("\n").uniq

        break true if statuses.size == 1 && statuses.first == "Running"

        if retry_count >= max_retry
          Rails.logger.warn("Containers aren't running... stopping!")
          break false
        end

        Rails.logger.info("Waiting #{wait} seconds... (#{retry_count}/#{max_retry} retries)")
        retry_count += 1
        sleep(wait)
      end
    end

    def setup_commands
      [
        ['apt-get update && apt-install -y build-essential && apt-get autoremove -y', false],
        ['curl -sfL https://get.k3s.io | sh -', false],
        ['k3s kubectl get node', true],
        ["git clone https://github.com/akinyele-spin/#{project_slug}", false],
        ["kubectl apply -f #{project_slug}", true],
      ]
    end

    def k8s_status_command
      'kubectl get pods --no-headers -o custom-columns=":status.phase"'
    end

    def project_slug
      droplet.project_request.project_slug
    end
  end
end
