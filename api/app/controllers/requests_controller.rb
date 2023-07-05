class RequestsController < ApplicationController
  def index
    render(
      json: Projects::Requests::List.perform(
        email: email,
      ),
    )
  end

  def show
    render(
      json: ProjectRequest.find_by(
        email: email,
        id: params[:id],
      ),
    )
  end

  def create
    render(
      json: Projects::Request.perform(
        email: email,
        project_slug: params[:project_slug],
        destroy_in: 1.day,
      )
    )
  end

  private

  def email
    Base64.urlsafe_decode64(params[:user_email])
  end
end
