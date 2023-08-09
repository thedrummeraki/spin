module Droplets
  module K8s
    class Secrets < ::Base
      property! :project_slug
      property :format, accepts: [:json, :yaml], default: :json

      def execute
        return [] unless all_secrets.present?

        k8s_configs
      end

      private

      def all_secrets
        return @all_secrets if @all_secrets.present?

        @all_secrets = Rails.application.credentials.projects[project_slug]
        return [] unless @all_secrets.present?

        @all_secrets
      end

      def k8s_configs
        all_secrets.map do |app, secrets|
          {
            filename: k8s_config_filename(app),
            data: k8s_config_data(app, secrets),
          }
        end
      end

      def k8s_config_data(app, secrets)
        {
          'apiVersion': 'v1',
          'kind': 'Secret',
          'metadata': {
            'name': "#{app}-secrets"
          },
          'data': encoded_secrets(secrets),
        }.send("to_#{format}")
      end

      def k8s_config_filename(app)
        "#{project_slug}/#{app}-secrets.#{format}"
      end

      def encoded_secrets(secrets)
        secrets.map do |key, value|
          [key, Base64.urlsafe_encode64(value)]
        end.to_h
      end
    end
  end
end
