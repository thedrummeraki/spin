class ProjectsController < ApplicationController
  def enable
    project = Projects::Ps.perform(project_slugs: [params[:slug]]).first
    if project.nil?
      render json: { message: 'no project was found' }, status: :unprocessable_entity
    else
      ProjectUpJob.perform_later(params[:slug])
      render json: { message: 'ok' }
    end
  end
end
