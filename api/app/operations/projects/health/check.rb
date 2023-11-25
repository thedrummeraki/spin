module Projects
  module Health
    class Check < ::Base
      # droplet was not created
      OFF = :off

      # droplet is there, but cannot ssh into it
      BOOTING_UP = :booting_up

      # droplet started but cannot be used
      UNAVAILABLE = :unavailable

      # droplet started but is not yet usable
      INITIALIZING = :initializing

      # droplet started and can be used
      ON = :on

      STATES = [OFF].freeze

      def execute
        slugs = Projects::Ps.perform
        slugs.map do |slug|
          {
            state: state_from_slug(slug),
            slug: slug,
          }
        end
      end

      private

      def running_droplets
        @running_droplets ||= client.droplets.all.map(&:name)
      end

      def state_from_slug(slug)
        return OFF unless droplet_on?(slug)

        droplet = find_droplet!(slug)
        return BOOTING_UP unless droplet.status == 'active'

        ON
      end

      def find_droplet!(slug)
        running_droplets.find do |droplet|
          droplet.name == slug
        end
      end

      def droplet_on?(slug)
        running_droplets.include?(slug)
      end
    end
  end
end
