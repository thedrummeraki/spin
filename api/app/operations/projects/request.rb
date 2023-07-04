require 'digest/sha2'

module Projects
  class Request < ::Base
    class ActiveRequestsError < StandardError
      def initialize(active_requests)
        @active_requests = active_requests
      end

      def message
        "This user has active requests: #{@active_requests.pluck(:project_slug).join(", ")}"
      end
    end

    property! :email, accepts: String
    property! :project_slug, accepts: String
    property! :destroy_in, accepts: ActiveSupport::Duration

    def execute
      ensure_request_for_project_not_made!
      project_request = create_request!
      create_droplet!(project_request)

      project_request
    end

    private

    def ensure_request_for_project_not_made!
      existing_requests = ProjectRequest.where(email: email, project_slug: project_slug)
      active_requests = existing_requests.reject(&:should_be_deleted?)

      return if active_requests.empty?

      raise Projects::Request::ActiveRequestsError.new(active_requests)
    end

    def create_request!
      ProjectRequest.create!(
        email: email,
        project_slug: project_slug,
        keep_until: destroy_in.from_now,
      )
    end

    def create_droplet!(project_request)
      ddroplet = DropletKit::Droplet.new(
        name: "#{project_slug}-#{hashed_email}",
        region: "tor1",
        image: "ubuntu-22-04-x64",
        size: "s-1vcpu-1gb",
      )
      digitalocean_id = Rails.configuration.x.dk_client.droplets.create(
        ddroplet,
      ).id

      droplet = Droplet.create(
        project_request: project_request,
        digitalocean_id: digitalocean_id,
      )
    end

    def hashed_email
      Digest::SHA256.hexdigest(email)
    end
  end
end
