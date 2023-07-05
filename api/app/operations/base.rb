class Base < ActiveOperation::Base
  protected

  def client
    Rails.configuration.x.dk_client
  end
end
