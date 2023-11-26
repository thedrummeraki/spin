module Projects
  class Slugify < ::Base
    property! :qualified_name, accepts: String
    property :where, accepts: [:first, :last], default: :last

    def execute
      root = QualifiedName::ROOT + "-"
      return unless qualified_name.include?(root)

      qualified_name.split(root).send(where)
    end
  end
end
