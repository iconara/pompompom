require 'hpricot'


module PomPomPom
  class Pom
    include UrlBuilder
    
    PROPERTIES = [:group_id, :artifact_id, :version, :name, :description, :url, :packaging]
    
    attr_reader *PROPERTIES
    attr_reader :parent
    
    def initialize(io, defaults={})
      @io = io
      merge_defaults!(defaults)
    end

    def parse!
      doc = Hpricot.XML(@io)
      parse_meta!(doc)
      parse_parent!(doc)
      parse_dependency_management!(doc)
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
    
    def merge(parent)
      defaults = Hash[*PROPERTIES.map { |p| [p, self.send(p) || parent.send(p)] }.flatten]
      defaults = defaults.merge(:parent => parent, :dependencies => @dependencies.dup, :dependency_management => @dependency_management.dup)
      self.class.new(nil, defaults)
    end
    
    def to_s
      to_dependency.to_s
    end
    
  protected
  
    def resolve_version(dependency)
      @dependency_management.find { |d| d.same_artifact?(dependency) } || dependency
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
    
    def merge_defaults!(defaults)
      PROPERTIES.each do |p|
        if defaults.has_key?(p)
          instance_variable_set('@' + p.to_s, defaults[p])
        end
      end
      
      @parent = defaults[:parent]
      
      default_dependencies = defaults.fetch(:dependencies, {})

      @dependencies = default_dependencies.keys.inject({}) do |deps, scope|
        deps[scope] = default_dependencies[scope].map do |dependency|
          if dependency.has_version?
            dependency
          elsif @parent
            @parent.resolve_version(dependency)
          end
        end
        deps
      end
      
      @dependency_management = defaults.fetch(:dependency_management, [])
    end

    def parse_meta!(doc)
      properties = PROPERTIES.map { |p| [p.to_s, snake_caseify(p.to_s)] }
      properties.each do |property, tag_name|
        val = doc.at("/project/#{tag_name}/text()")
        instance_variable_set('@' + property, val.to_s) if val
      end
    end
    
    def parse_parent!(doc)
      parent_node = doc.at("/project/parent")
      @parent = parse_dependency(parent_node) if parent_node
    end

    def parse_dependencies!(doc)
      doc.search('/project/dependencies/dependency').each do |dep_node|
        scope = parse_scope(dep_node)
        @dependencies[scope] ||= []
        @dependencies[scope] << parse_dependency(dep_node)
      end
    end
    
    def parse_dependency_management!(doc)
      doc.search('/project/dependencyManagement/dependencies/dependency').each do |dep_node|
        @dependency_management << parse_dependency(dep_node)
      end
    end
    
    def parse_dependency(dep_node)
      Dependency.new(
        :group_id    => parse_attr(dep_node, 'groupId'),
        :artifact_id => parse_attr(dep_node, 'artifactId'),
        :version     => parse_version(dep_node),
        :optional    => parse_attr(dep_node, 'optional').downcase == 'true',
        :exclusions  => parse_exclusions(dep_node)
      )
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
