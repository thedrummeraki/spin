class ProjectDownJob < ApplicationJob
  queue_as :default

  def perform(project_slug)
    Projects::Down.perform(project_slug: project_slug)
  end
end
