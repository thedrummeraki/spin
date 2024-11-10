module Projects
  class QualifiedName < ::Base
    property! :project_slug, accepts: String

    ROOT = 'akinyele-spin'.freeze

    def execute
      [ROOT, sanitized_project_slug].join('-')
    end

    private

    def sanitized_project_slug
      project_slug.gsub('/', '-')
    end
  end
end
