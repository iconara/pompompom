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
      parse_properties!(doc)
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
    
    def properties
      if has_parent? && @parent.respond_to?(:properties)
        @parent.properties.merge(@properties)
      else
        @properties || {}
      end
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
      defaults = defaults.merge(
        :parent => parent,
        :dependencies => @dependencies.dup,
        :dependency_management => @dependency_management.dup,
        :properties => @properties.dup
      )
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

    def camelize(str)
      if str.include?('_')
        components = str.split('_')
        components.first + components[1..-1].map { |s| s.capitalize }.join('')
      else
        str
      end
    end
    
    def snakeify(str)
      str.gsub(/([a-z])([A-Z])/) do |match|
        "#{$1}_#{$2.downcase}"
      end
    end
    
    def merge_defaults!(defaults)
      @parent = defaults[:parent]
      @dependency_management = defaults.fetch(:dependency_management, [])
      @properties = defaults.fetch(:properties, [])
      
      PROPERTIES.each do |p|
        if defaults.has_key?(p)
          value = defaults[p]
          value = expand_properties(value) if value
          instance_variable_set('@' + p.to_s, value)
        end
      end
      
      default_dependencies = defaults.fetch(:dependencies, {})

      @dependencies = default_dependencies.keys.inject({}) do |deps, scope|
        deps[scope] = default_dependencies[scope].map do |dependency|
          dependency = dependency.clone(
            :group_id    => expand_properties(dependency.group_id),
            :artifact_id => expand_properties(dependency.artifact_id),
            :version     => expand_properties(dependency.version)
          )
          
          if dependency.has_version?
            dependency
          elsif @parent
            @parent.resolve_version(dependency)
          end
        end
        deps
      end
    end

    def parse_properties!(doc)
      @properties = {}
      doc.search('/project/properties/*').each do |property_node|
        if property_node.elem?
          @properties[property_node.name] = property_node.inner_text.to_s
        end
      end
    end

    def parse_meta!(doc)
      properties = PROPERTIES.map { |p| [p.to_s, camelize(p.to_s)] }
      properties.each do |property, tag_name|
        val = doc.at("/project/#{tag_name}/text()")
        instance_variable_set('@' + property, expand_properties(val.to_s)) if val
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
      str = expand_properties(dep_node.at("#{attr_name}/text()").to_s)
    end
    
    def expand_properties(str)
      return nil if str.nil?
      str.gsub(/\$\{([.\w]+)\}/) do |match|
        property_value($1)
      end
    end
    
    def property_value(property_name)
      custom_properties = {'version' => @version}.merge(properties)
      if custom_properties.has_key?(property_name)
        custom_properties[property_name]
      else
        components = property_name.split('.')
        if components.first == 'project' && components.size == 2 && self.respond_to?(snakeify(components[1]))
          self.send(snakeify(components[1]))
        elsif components.first == 'env' && components.size == 2
          ENV[components[1]]
        #elsif components.first == 'settings' # not yet supported
        else
          "${#{property_name}}"
        end
      end
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
