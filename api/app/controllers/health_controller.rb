class HealthController < ApplicationController
  def check
    render json: Projects::Health::Check.perform
  end
end
