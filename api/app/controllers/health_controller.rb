class HealthController < ApplicationController
  def check
    render json: Projects::Health::Check.perform
  end

  def show
    render json: Projects::Health::Check.perform(project_slug: params[:slug])
  end
end
