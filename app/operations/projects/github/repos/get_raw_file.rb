module Projects
  module Github
    module Repos
      class GetRawFile < ::Base
        property! :repo, accepts: String
        property! :path, accepts: String
        property :branch, accepts: String, default: "main"
        property :owner, accepts: ["akinyele-spin", "thedrummeraki"], default: "akinyele-spin"

        def execute
          file_contents
        end

        private

        def file_contents
          response = Net::HTTP.get_response(uri)
          if !response.is_a?(Net::HTTPOK)
            Rails.logger.warn("Could not find file on Github (#{uri}).")
            return
          end

          response.body
        end

        def uri
          url = [
            "https://raw.githubusercontent.com/#{owner}",
            "#{repo}/#{branch}/#{path}"
          ].join('/')

          URI(url)
        end
      end
    end
  end
end
