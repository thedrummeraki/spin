module Projects
  module Errors
    class Base < StandardError; end

    class NotFound < Base
      def initialize(project_slug)
        @project_slug = project_slug
      end

      def message
        "Project was not found (id: #{@project_slug})"
      end
    end
  end
end
