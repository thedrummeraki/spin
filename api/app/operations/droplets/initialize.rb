module Droplets
  class Initialize < ::Base
    property! :project_slug, accepts: String
    property! :droplet_id, converts: :to_i

    def execute
      ensure_exists_on_github!
      init_droplet!
    end

    private

    def ensure_exists_on_github!
      return if Projects::Github::Exists.perform(project_slug: project_slug)

      raise Projects::Errors::NotFound, project_slug
    end

    def init_droplet!
      return unless exists_on_digitalocean?

      wait_for_droplet_to_be_available(every: 2)
      skip_init = project_checked_out?
      execute_initialization_commands!(skip_init)

      create_domain_record_if_missing!(droplet.public_ip)
    end

    def exists_on_digitalocean?
      droplet!.present?
    end

    def droplet
      @droplet ||= droplet!
    end

    def droplet!
      Rails.configuration.x.dk_client.droplets.find(
        id: droplet_id,
      )
    rescue DropletKit::Error
      nil
    end

    def wait_for_droplet_to_be_available(every:)
      Rails.logger.info("Waiting for droplet to be available...")
      loop do
        status = droplet!.status
        break if status == 'active'

        sleep(every)
      end
    end

    def create_domain_record_if_missing!(public_ip)
      existing_domain_record = client.domain_records.all(for_domain: Domain::NAME).find do |domain_record|
        domain_record.name == project_slug && domain_record.type == 'A'
      end

      domain_record = DropletKit::DomainRecord.new(
        type: 'A',
        name: project_slug,
        data: public_ip,
        ttl: 3600,
      )

      if existing_domain_record.nil?
        client.domain_records.create(domain_record, for_domain: Domain::NAME)
      else
        client.domain_records.update(domain_record, for_domain: Domain::NAME, id: existing_domain_record.id)
      end
    end

    def execute_initialization_commands!(skip_init)
      Net::SSH.start(droplet.public_ip, 'root') do |ssh|
        if skip_init
          Rails.logger.info('Project was checked out, skipping initialization...')
        else
          setup_commands.each do |command, with_output|
            next if command.blank?

            execute_ssh_command!(ssh, command, with_output)
          end
        end

        check_containers_all_running!(ssh, wait: 10)
      end
    rescue Errno::ECONNREFUSED
      Rails.logger.warn("Address #{droplet.public_ip} not available yet, retrying in 5 seconds...")
      sleep(5)
      retry
    end

    def project_checked_out?
      status = {}

      Net::SSH.start(droplet.public_ip, 'root') do |ssh|
        command = "ls #{project_slug}"
        ssh.exec!(command, status: status)
      end

      status[:exit_code] == 0
    rescue Errno::ECONNREFUSED
      Rails.logger.warn("Address #{droplet.public_ip} not available yet, retrying in 5 seconds...")
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
      max_retry = 30
      retry_count = 0

      loop do
        Rails.logger.info("Executing command: #{k8s_status_command}")
        output = ssh.exec!(k8s_status_command)
        statuses = output.split("\n").uniq

        if statuses.size == 1 && statuses.first == "Running"
          Rails.logger.info("Project is up and running.")
          break true
        end

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
      basic_commands = [
        ['apt-get update && apt-install -y build-essential && apt-get autoremove -y', false],
        ['curl -sfL https://get.k3s.io | sh -', false],
        ['k3s kubectl get node', true],
        ["git clone https://github.com/akinyele-spin/#{project_slug}", false],
      ]

      write_k8s_secrets_config_commands.each do |command|
        basic_commands.push([command, false])
      end

      basic_commands.push(["kubectl apply -f #{project_slug}", true])
      basic_commands
    end

    def k8s_status_command
      'kubectl get pods --no-headers -o custom-columns=":status.phase"'
    end

    def write_k8s_secrets_config_commands
      k8s_configs = Droplets::K8s::Secrets.perform(project_slug: project_slug)
      k8s_configs.map do |k8s_config|
        "echo \'#{k8s_config[:data]}\' > \"#{k8s_config[:filename]}\""
      end
    end
  end
end
