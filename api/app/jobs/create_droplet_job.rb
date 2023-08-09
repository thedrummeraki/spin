class CreateDropletJob < ApplicationJob
  queue_as :default

  def perform(project_request_id)
    project_request = ProjectRequest.find(project_request_id)
    Droplets::Create.perform(project_request: project_request)
  end
end
