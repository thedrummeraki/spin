module Projects
  class Ps < ::Base
    property :project_slugs, converts: -> (value) {Array.wrap(value).to_set}

    def execute
      valid_slugs.map do |slug|
        Projects::QualifiedName.perform(project_slug: slug)
      end
    end

    private

    def requested_slugs
      project_slugs || Set.new
    end

    def valid_slugs
      return existing_project_slugs if project_slugs.blank?

      existing_project_slugs & project_slugs
    end

    def existing_project_slugs
      return @existing_project_slugs if @existing_project_slugs.present?

      projects = Projects::Github::Repos::List.perform
      @existing_project_slugs = projects.map { |project| project['name'] }.to_set
    end

    def existing_droplets
    end
  end
end
