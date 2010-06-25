require 'hpricot'


module PomPomPom
  class Pom
    PROPERTIES = [:group_id, :artifact_id, :version, :name, :description, :url, :model_version, :packaging]
    
    attr_reader *PROPERTIES
    
    def initialize(io)
      @io = io
      @dependencies = { }
    end

    def parse!
      @doc = Hpricot.XML(@io)
      parse_meta!
      parse_dependencies!
    end
    
    def dependencies(scope = :default)
      @dependencies.fetch(scope, []).dup
    end
    
  private

    def snake_caseify(str)
      if str.include?('_')
        components = str.split('_')
        components.first + components[1..-1].map { |s| s.capitalize }.join('')
      else
        str
      end
    end

    def parse_meta!
      properties = PROPERTIES.map { |p| [p.to_s, snake_caseify(p.to_s)] }
      properties.each do |property, tag_name|
        instance_variable_set('@' + property, @doc.at("/project/#{tag_name}/text()").to_s)
      end
    end

    def parse_dependencies!
      @doc.search('/project/dependencies/dependency').each do |dep_node|
        scope = dep_node.at('scope/text()').to_s
        scope = 'default' if scope.nil? || scope.strip.length == 0
        scope = scope.to_sym
        @dependencies[scope] ||= []
        @dependencies[scope] << Dependency.new(
          dep_node.at('groupId/text()').to_s,
          dep_node.at('artifactId/text()').to_s,
          dep_node.at('version/text()').to_s
        )
      end
    end
  end
end
