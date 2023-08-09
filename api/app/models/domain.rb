class Domain < ApplicationRecord
  NAME = "akinyele-demos.ca".freeze

  belongs_to :project_request
  before_destroy :destroy_on_digitalocean!

  delegate :name, to: :digitalocean_instance, allow_nil: true

  def exists_on_digitalocean?
    digitalocean_instance!.present?
  end

  def digitalocean_instance
    @do_instance ||= digitalocean_instance!
  end

  def digitalocean_instance!
    Rails.configuration.x.dk_client.domain_records.find(
      id: digitalocean_id,
      for_domain: NAME,
    )
  rescue DropletKit::Error
    nil
  end

  private

  def destroy_on_digitalocean!
    return unless exists_on_digitalocean?

    Rails.logger.info("Cleaning up domain \"#{name}\" (#{digitalocean_instance.id})")
    Rails.configuration.x.dk_client.domain_records.delete(
      id: digitalocean_id,
      for_domain: NAME,
    )
  end
end
