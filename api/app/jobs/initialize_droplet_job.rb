class InitializeDropletJob < ApplicationJob
  queue_as :default

  def perform(project_slug, droplet_id)
    Droplets::Initialize.perform(project_slug: project_slug, droplet_id: droplet_id)
  end
end
