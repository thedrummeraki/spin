class ProjectRequest < ApplicationRecord
  has_one :droplet

  def should_be_deleted?
    keep_until < Time.now
  end
end
