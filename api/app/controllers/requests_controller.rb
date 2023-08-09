class RequestsController < ApplicationController
  def index
    render(
      json: Projects::Requests::List.perform(
        email: email,
      ),
    )
  end

  def show
    project_request = ProjectRequest.find_by(
      email: email,
      id: params[:id],
    )

    render(json: project_request_data(project_request))
  end

  def create
    project_request = Projects::Request.perform(
      email: email,
      project_slug: params[:project_slug],
      destroy_in: 3.hours,
    )

    render(json: project_request_data(project_request))
  end

  private

  def project_request_data(project_request)
    return if project_request

    {
      id: project_request.id,
      app_url: project_request.app_url,
      status: project_request.status,
    }
  end

  def email
    Base64.urlsafe_decode64(params[:user_email])
  end
end
