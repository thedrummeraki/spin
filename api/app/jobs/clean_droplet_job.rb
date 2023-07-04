class CleanDropletJob < ApplicationJob
  queue_as :default

  def perform(email)
    client = Rails.configuration.x.dk_client
    project_requests = ProjectRequest.where(email: email)
    return unless project_requests.any?

    project_requests.each do |project_request|
      clean_up(project_request)
    end
  end

  private

  def clean_up(project_request)
    droplet = project_request.droplet
    return unless droplet.present?

    droplet.destroy
  end
end
