require 'hpricot'


module PomPomPom
  class Pom
    include UrlBuilder
    
    PROPERTIES = [:group_id, :artifact_id, :version, :name, :description, :url, :model_version, :packaging]
    
    attr_reader *PROPERTIES
    
    def initialize(io)
      @io = io
      @dependencies = { }
    end

    def parse!
      doc = Hpricot.XML(@io)
      parse_meta!(doc)
      parse_dependencies!(doc)
    end
    
    def dependencies(scope = :default)
      @dependencies.fetch(scope, []).dup
    end
    
    def exclusions
      []
    end
    
    def to_dependency
      Dependency.new(
        :group_id => group_id,
        :artifact_id => artifact_id, 
        :version => version, 
        :packaging => packaging,
        :dependencies => dependencies
      )
    end
    
    def to_s
      to_dependency.to_s
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

    def parse_meta!(doc)
      properties = PROPERTIES.map { |p| [p.to_s, snake_caseify(p.to_s)] }
      properties.each do |property, tag_name|
        instance_variable_set('@' + property, doc.at("/project/#{tag_name}/text()").to_s)
      end
    end

    def parse_dependencies!(doc)
      doc.search('/project/dependencies/dependency').each do |dep_node|
        scope = parse_scope(dep_node)
        @dependencies[scope] ||= []
        @dependencies[scope] << Dependency.new(
          :group_id => parse_attr(dep_node, 'groupId'),
          :artifact_id => parse_attr(dep_node, 'artifactId'),
          :version => parse_attr(dep_node, 'version'),
          :optional => parse_attr(dep_node, 'optional').downcase == 'true',
          :exclusions => parse_exclusions(dep_node)
        )
      end
    end
    
    def parse_attr(dep_node, attr_name)
      dep_node.at("#{attr_name}/text()").to_s
    end
    
    def parse_scope(dep_node)
      scope = parse_attr(dep_node, 'scope')
      scope = 'default' if scope.nil? || scope.strip.length == 0
      scope.to_sym
    end
    
    def parse_exclusions(dep_node)
      dep_node.search('exclusions/exclusion').map do |excl_node|
        Dependency.new(
          parse_attr(excl_node, 'groupId'),
          parse_attr(excl_node, 'artifactId')
        )
      end
    end
  end
end
