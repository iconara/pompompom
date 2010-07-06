require 'hpricot'


module PomPomPom
  class Pom
    include UrlBuilder
    
    PROPERTIES = [:group_id, :artifact_id, :version, :name, :description, :url, :packaging]
    
    attr_reader *PROPERTIES
    attr_reader :parent
    
    def initialize(io)
      @io = io
      @dependencies = { }
    end

    def parse!
      doc = Hpricot.XML(@io)
      parse_meta!(doc)
      parse_parent!(doc)
      parse_dependencies!(doc)
    end
    
    def dependencies(scope = :default)
      @dependencies.fetch(scope, []).dup
    end
    
    def exclusions
      []
    end
    
    def has_parent?
      !!parent
    end
    
    def group_id
      @group_id || parent.group_id
    end
    
    def artifact_id
      @artifact_id || parent.artifact_id
    end
    
    def version
      @version || parent.version
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
      project_node = doc.at("/project")
      properties = PROPERTIES.map { |p| [p.to_s, snake_caseify(p.to_s)] }
      properties.each do |property, tag_name|
        instance_variable_set('@' + property, parse_attr(project_node, tag_name))
      end
    end
    
    def parse_parent!(doc)
      parent_node = doc.at("/project/parent")
      if parent_node
        @parent = Dependency.new(
          :group_id => parse_attr(parent_node, 'groupId'),
          :artifact_id => parse_attr(parent_node, 'artifactId'),
          :version => parse_attr(parent_node, 'version')
        )
      end
    end

    def parse_dependencies!(doc)
      doc.search('/project/dependencies/dependency').each do |dep_node|
        scope = parse_scope(dep_node)
        @dependencies[scope] ||= []
        @dependencies[scope] << Dependency.new(
          :group_id => parse_attr(dep_node, 'groupId'),
          :artifact_id => parse_attr(dep_node, 'artifactId'),
          :version => parse_version(dep_node),
          :optional => parse_attr(dep_node, 'optional').downcase == 'true',
          :exclusions => parse_exclusions(dep_node)
        )
      end
    end
    
    def parse_attr(dep_node, attr_name)
      str = dep_node.at("#{attr_name}/text()").to_s
    end
    
    def parse_version(dep_node)
      v = parse_attr(dep_node, 'version')
      if v.length == 0 then nil else v end
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
