require 'immutable_struct'


module PomPomPom
  class Dependency < ImmutableStruct.new(:group_id, :artifact_id, :version)
  end
end
