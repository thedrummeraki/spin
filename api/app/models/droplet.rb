class Droplet < ApplicationRecord
  belongs_to :project_request
  before_destroy :destroy_on_digitalocean

  delegate :name, to: :digitalocean_instance, allow_nil: true
  delegate :public_ip, to: :digitalocean_instance!

  def exists_on_digitalocean?
    digitalocean_instance!.present?
  end

  def digitalocean_instance
    @do_instance ||= digitalocean_instance!
  end

  def digitalocean_instance!
    Rails.configuration.x.dk_client.droplets.find(
      id: digitalocean_id,
    )
  rescue DropletKit::Error
    nil
  end

  def app_host(port: 31000, https: false)
    return unless exists_on_digitalocean?

    klass = https ? URI::HTTPS : URI::HTTP
    klass.build(host: public_ip, port: port).to_s
  end

  private

  def destroy_on_digitalocean
    return unless exists_on_digitalocean?

    Rails.logger.info("Cleaning up droplet \"#{name}\"")
    Rails.configuration.x.dk_client.droplets.delete(
      id: digitalocean_id,
    )
  end
end
