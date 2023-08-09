class SshKey < ApplicationRecord
  belongs_to :droplet
  before_destroy :destroy_on_digitalocean!

  delegate :name, :fingerprint, to: :digitalocean_instance, allow_nil: true

  def exists_on_digitalocean?
    digitalocean_instance!.present?
  end

  def digitalocean_instance
    @do_instance ||= digitalocean_instance!
  end

  def digitalocean_instance!
    Rails.configuration.x.dk_client.ssh_keys.find(
      id: digitalocean_id,
    )
  rescue DropletKit::Error
    nil
  end

  private

  def destroy_on_digitalocean!
    return unless exists_on_digitalocean?

    Rails.logger.info("Cleaning up SSH key \"#{name}\" with fingerprint #{fingerprint} (#{digitalocean_instance.id})")
    Rails.configuration.x.dk_client.ssh_keys.delete(
      id: digitalocean_id,
    )
  end
end
