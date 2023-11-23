class ProjectUpJob < ApplicationJob
  queue_as :default

  def perform(project_slug)
    Projects::Up.perform(project_slug: project_slug)
  end
end
