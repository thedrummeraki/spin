module Projects
  module Github
    class Exists < ::Base
      property! :project_slug
  
      def execute
        exists_on_github?
      end
  
      private
  
      def exists_on_github?
        Repos::Get.perform(project_slug: project_slug).present?
      end
    end
  end
end
