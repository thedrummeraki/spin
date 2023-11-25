module Projects
  module Github
    module Repos
      class List < ::Base
        def execute
          Array.wrap(list_repos_in_org)
        end

        private

        def list_repos_in_org
          uri = URI('https://api.github.com/orgs/akinyele-spin/repos')
          response = Net::HTTP.get_response(uri)
          return unless response.is_a?(Net::HTTPOK)

          JSON.parse(response.body)
        end
      end
    end
  end
end
