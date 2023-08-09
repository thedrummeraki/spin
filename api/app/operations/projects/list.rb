module Projects
  class List < ::Base
    def execute
      results = filtered_project_requests
      clean_up_expired_projects_later

      results
    end

    private

    def filtered_project_requests
      project_requests.reject(&:should_be_deleted?)
    end

    def clean_up_expired_projects_later
      CleanDropletJob.perform_later(email) if project_requests.any?
    end

    def project_requests
      @project_requests ||= ProjectRequest.where(
        email: email,
      )
    end
  end
end
