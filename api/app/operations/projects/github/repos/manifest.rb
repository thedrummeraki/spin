module Projects
  module Github
    module Repos
      class Manifest < ::Base
        property! :project_slug, accepts: String
        property :branch, accepts: String, default: "main"

        def execute
          (fetch_manifest || default_manifest).with_indifferent_access
        end

        private

        def fetch_manifest
          Rails.logger.info("Fetching manifest from Github...")
          file_contents = GetRawFile.perform(
            owner: "thedrummeraki",
            repo: "spin-manifest",
            path: "#{project_slug}.json",
            branch: branch,
          )
          if file_contents.blank?
            Rails.logger.warn("Using default manifest...")
            return
          end

          JSON.parse(file_contents)
        rescue JSON::ParserError => e
          Rails.logger.error("Could not parse manifest file. Using default manifest...")
          nil
        end

        def default_manifest
          {
            slug: project_slug,
            description: "Project #{project_slug}",
            details: nil,
            github: [],
            about: nil,
            droplet: {
              config: {
                size: "s-1vcpu-2gb",
                image: "ubuntu-22-04-x64",
                region: "tor1"
              },
              on: {
                up: [],
                down: []
              }
            }
          }
        end
      end
    end
  end
end
