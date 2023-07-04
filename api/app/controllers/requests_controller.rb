class RequestsController < ApplicationController
  def index
    render(
      json: Projects::Requests::List.perform(
        email: params[:user_email],
      ),
    )
  end

  def show
    render(
      json: ProjectRequest.find_by(
        email: params[:user_email],
        id: params[:id],
      ),
    )
  end

  def create
  end
end
