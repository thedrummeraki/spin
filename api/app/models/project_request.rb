class ProjectRequest < ApplicationRecord
  has_one :droplet, dependent: :destroy

  delegate :app_host, to: :droplet

  def should_be_deleted?
    keep_until < Time.now
  end
end
