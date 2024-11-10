module Projects
  module Github
    module Repos
      class Get < ::Base
        property! :project_slug, accepts: String
    
        def execute
          find_project_by_slug
        end
    
        private
    
        def find_project_by_slug
          response = Net::HTTP.get_response(github_repo_uri)
          return unless response.is_a?(Net::HTTPOK)
    
          JSON.parse(response.body)
        end
    
        def github_repo_uri
          path = ['akinyele-spin', project_slug].join('/')
          url = ['https://api.github.com/repos', path].join('/')
          URI(url)
        end
      end
    end
  end
end
