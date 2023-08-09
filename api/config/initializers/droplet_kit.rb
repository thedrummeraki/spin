Rails.configuration.x.dk_client = DropletKit::Client.new(access_token: ENV.fetch('TOKEN'))
Rails.configuration.x.project_id = ENV.fetch('PROJECT_ID') { '616a819b-d356-4219-8d32-65e8c133211b' }
