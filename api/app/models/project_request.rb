class ProjectRequest < ApplicationRecord
  has_one :droplet, dependent: :destroy

  def should_be_deleted?
    keep_until < Time.now
  end
end
