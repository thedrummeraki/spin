module Projects
  module Health
    class Check < ::Base
      # droplet was not created
      OFF = :off

      # droplet is there, but cannot ssh into it
      BOOTING_UP = :booting_up

      # droplet started but cannot be used
      UNKNOWN = :unknown

      # droplet status cannot be reached from here
      UNREACHABLE = :unreachable

      # droplet started but is not yet usable
      INITIALIZING = :initializing

      # droplet usable but project not ready yet
      WAITING = :waiting

      # project failed to start
      FAILED = :failed

      # droplet started and can be used
      ON = :on

      property :project_slug, accepts: String

      STATES = [OFF].freeze

      def execute
        ensure_ssh_keys!

        if project_slug
          qualified_name = Projects::Ps.perform(project_slugs: project_slug).first
          if qualified_name.nil?
            Rails.logger.error("Project with slug #{project_slug} doesn't exist.")
            nil
          else
            health_options(qualified_name)
          end
        else
          qualified_names = Projects::Ps.perform
          qualified_names.map do |qualified_name|
            health_options(qualified_name)
          end
        end
      end

      private

      def health_options(qualified_name)
        options = { name: qualified_name }

        unless droplet_on?(qualified_name)
          options[:state] = OFF
          return options
        end

        droplet = find_droplet!(qualified_name)
        with_ssh_client(droplet) do |ssh|
          options.merge!(health_options_droplet_on(ssh, droplet))
        end
  
        options
      end

      def with_ssh_client(droplet, &block)
        Net::SSH.start(droplet.public_ip, 'root', timeout: 2) do |ssh|
          yield ssh
        end
      rescue Net::SSH::AuthenticationFailed, Net::SSH::ConnectionTimeout, Errno::ECONNREFUSED => e
        Rails.logger.error("Failed with SSH error: #{e}")
        yield nil
      rescue => e
        Rails.logger.error("Unknown SSH error: #{e}")
        yield nil
      end

      def health_options_droplet_on(ssh, droplet)
        options = {}
        options[:state] = state_from_droplet_name(ssh, droplet)
        return options if options[:state] == BOOTING_UP

        options[:public_ip] = droplet.public_ip
        options[:port] = port_for(droplet)

        options[:domain] = domain_for(droplet)
        options[:app_uri] = app_uri_for(droplet)

        Rails.logger.info("Project status for #{droplet.public_ip}: #{project_status!(ssh, droplet)}")

        options
      end

      def slug_for(droplet)
        Projects::Slugify.perform(qualified_name: droplet.name)
      end

      def running_droplets
        @running_droplets ||= client.droplets.all
      end

      def state_from_droplet_name(ssh, droplet)
        return UNREACHABLE if ssh.nil? && !ssh_key_exists?
        return BOOTING_UP if ssh.nil? && ssh_key_exists?

        return FAILED if project_failed?(ssh, droplet)
        return WAITING if project_pending?(ssh, droplet)
        return ON if project_running?(ssh, droplet)

        UNKNOWN
      rescue Errno::ECONNREFUSED
        INITIALIZING
      rescue Net::SSH::AuthenticationFailed, Net::SSH::ConnectionTimeout
        BOOTING_UP
      end

      def ssh_accessible?(droplet)
        Net::SSH.start(droplet.public_ip, 'root', timeout: 2)
        true
      rescue Errno::ECONNREFUSED
        false
      end

      def project_status!(ssh, droplet)
        return [] if ssh.blank?

        output = ssh.exec!(k8s_status_command)
        output.split("\n").uniq
      end

      def project_running?(ssh, droplet)
        return false if ssh.blank?

        statuses = project_status!(ssh, droplet).to_set
        statuses.include?("Running") || statuses.include?("Succeeded")
      rescue Errno::ECONNREFUSED
        false
      end

      def project_failed?(ssh, droplet)
        statuses = project_status!(ssh, droplet)
        statuses.include?('Failed')
      rescue Errno::ECONNREFUSED
        false
      end

      def project_pending?(ssh, droplet)
        statuses = project_status!(ssh, droplet)
        statuses.empty? || statuses.include?('Pending') || statuses.include?('bash: line 1: kubectl: command not found')
      rescue Errno::ECONNREFUSED
        false
      end

      def find_droplet!(qualified_name)
        running_droplets.find do |droplet|
          droplet.name == qualified_name
        end
      end

      def droplet_on?(qualified_name)
        running_droplets.any? do |droplet|
          droplet.name == qualified_name
        end
      end

      def port_for(_droplet)
        31000
      end

      def app_uri_for(droplet)
        "http://#{domain_for(droplet)}:#{port_for(droplet)}"
      end

      def domain_for(droplet)
        existing_domain_record = client.domain_records.all(for_domain: Domain::NAME).find do |domain_record|
          domain_record.name == slug_for(droplet) && domain_record.type == 'A'
        end

        return droplet.public_ip if existing_domain_record.nil?

        [existing_domain_record.name, Domain::NAME].join('.')
      end

      def k8s_status_command
        'kubectl get pods --no-headers -o custom-columns=":status.phase"'
      end
    end
  end
end
