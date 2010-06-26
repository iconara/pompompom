require 'immutable_struct'


module PomPomPom
  class Dependency < ImmutableStruct.new(:group_id, :artifact_id, :version)
    include UrlBuilder
    
    def to_s
      "#{group_id}:#{artifact_id}:jar:#{version}"
    end
  end
end
