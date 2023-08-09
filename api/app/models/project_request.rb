class ProjectRequest < ApplicationRecord
  has_one :droplet, dependent: :destroy
  has_one :domain, dependent: :destroy

  delegate :app_url, to: :droplet
  delegate :status, to: :droplet, allow_nil: true

  def should_be_deleted?
    keep_until < Time.now || droplet.nil? || (droplet? && droplet.exists_on_digitalocean?)
  end

  def droplet?
    droplet.present?
  end

  def sanitized_project_slug
    project_slug&.gsub('/', '-')
  end
end
