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

  
  def ssh_key_exists?
    ensure_ssh_keys!

    File.exist?(private_key_filename) && File.exist?(public_key_filename)
  end
  
  def ssh_key_uploaded?
    public_key, _ = ssh_key_pair
    client.ssh_keys.all.any? do |ssh_key|
      ssh_key.public_key == public_key
    end
  end

  def ensure_ssh_keys!
    private_key_data = Rails.application.credentials.ssh_key

    File.write(private_key_filename, private_key_data)
  end

  def ssh_key_pair
    ensure_ssh_keys!

    private_key = File.read(private_key_filename)
    public_key = File.read(public_key_filename)

    [public_key, private_key]
  end

  private

  def private_key_filename
    "#{ENV['HOME']}/.ssh/id_rsa"
  end

  def public_key_filename
    "#{private_key_filename}.pub"
  end
end
