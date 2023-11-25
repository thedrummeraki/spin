class Base < ActiveOperation::Base
  protected

  def client
    Rails.configuration.x.dk_client
  end

  def ensure_exists_on_github!
    return if Projects::Github::Exists.perform(project_slug: project_slug)

    raise Projects::Errors::NotFound, project_slug
  end

  def qualified_name
    Projects::QualifiedName.perform(project_slug: project_slug)
  end
end
