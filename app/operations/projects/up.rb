
require 'digest/sha2'

module Projects
  class Up < ::Base
    property! :project_slug, accepts: String

    def execute
      ensure_exists_on_github!

      droplet = digitalocean_instance
      return droplet if droplet.present?

      Rails.logger.info("Project #{project_slug} does not exist at the moment.")
      create_droplet_later
      schedule_for_deletion_later
    end

    private

    def ensure_exists_on_github!
      Rails.logger.info("Checking if #{project_slug} exists on Github...")
      return if Projects::Github::Exists.perform(project_slug: project_slug)

      raise Errors::NotFound, project_slug
    end

    def digitalocean_instance
      client.droplets.all.find do |droplet|
        droplet.name == qualified_name
      end
    end

    def create_droplet_later
      CreateProjectDropletJob.perform_later(project_slug)
    end

    def schedule_for_deletion_later
      Rails.logger.info("Scheduling #{project_slug} to be deleted in approximately 3 hours...")
      ProjectDownJob.perform_in(3.hours, project_slug)
    end
  end
end
