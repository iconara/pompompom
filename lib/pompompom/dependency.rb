require 'immutable_struct'


module PomPomPom
  class Dependency < ImmutableStruct.new(:group_id, :artifact_id, :version, :packaging, :classifier, :optional, :exclusions)
    include UrlBuilder
    
    def self.parse(artifact_coordinates)
      raise ArgumentError, %(Malformed artifact coordinate: "#{artifact_coordinates}") if artifact_coordinates.nil? || artifact_coordinates.strip.length == 0
      components = artifact_coordinates.strip.split(':')
      raise ArgumentError, %(Malformed artifact coordinate: "#{artifact_coordinates}") if components.size < 3 || components.size > 5
      case components.size
      when 3
        group_id, artifact_id, version = components
      when 4
        group_id, artifact_id, packaging, version = components
      when 5
        group_id, artifact_id, packaging, classifier, version = components
      end
      Dependency.new(group_id, artifact_id, version, packaging, classifier)
    end
    
    def exclusions
      self[:exclusions] || []
    end
    
    def optional?
      optional
    end
    
    def eql?(o)
      o.to_s == to_s
    end
    
    def hash
      to_s.hash
    end
    
    def to_s
      "#{group_id}:#{artifact_id}:#{version}"
    end
  end
end
