
require 'digest/sha2'

module Projects
  class Down < ::Base
    property! :project_slug, accepts: String

    def execute
      remove_domain_record_if_exists!
      remove_ssh_key_if_exists_and_unsued!
      remove_droplet_if_exists!
    end

    private

    def remove_domain_record_if_exists!
      domain_records = client.domain_records.all(for_domain: Domain::NAME).filter do |domain_record|
        domain_record.name == project_slug && domain_record.type == 'A'
      end
      return unless domain_records.any?

      domain_records.each do |domain_record|
        Rails.logger.info("Removing domain record #{domain_record.name} for domain #{Domain::NAME}...")
        client.domain_records.delete(id: domain_record.id, for_domain: Domain::NAME)
      end
    end

    def remove_ssh_key_if_exists_and_unsued!
      # ssk_key_name = "#{qualified_name}-auto-generated"
      # ssh_keys = client.ssh_keys.all.filter do |ssh_key|
      #   ssh_key.name == ssk_key_name
      # end
      # return unless ssh_keys.any?

      # ssh_keys.each do |ssh_key|
      #   Rails.logger.info("Removing SSH key #{ssh_key.name} (#{ssh_key.fingerprint}) ...")
      #   client.ssh_keys.delete(id: ssh_key.id)
      # end
    end

    def remove_droplet_if_exists!
      droplets = client.droplets.all.filter do |droplet|
        droplet.name == qualified_name
      end
      return unless droplets.any?

      droplets.each do |droplet|
        Rails.logger.info("Removing droplet #{droplet.name} (#{droplet.id})...")
        client.droplets.delete(id: droplet.id)
      end
    end
  end
end
