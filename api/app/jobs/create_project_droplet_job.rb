class CreateProjectDropletJob < ApplicationJob
  queue_as :default

  def perform(project_slug)
    Projects::Droplets::Create.perform(project_slug: project_slug)
  end
end
