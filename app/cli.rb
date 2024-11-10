require_relative 'operations'

slug = "tanoshimu"
puts(Projects::QualifiedName.perform(project_slug: slug))
