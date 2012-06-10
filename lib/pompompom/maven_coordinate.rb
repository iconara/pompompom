# encoding: utf-8

module PomPomPom
  class MavenCoordinate
    def self.parse(str)
      new(*str.split(':'))
    end

    attr_reader :group_id, :artifact_id, :version

    def initialize(*args)
      @group_id, @artifact_id, @version = args
    end

    begin :conversions
      def to_s
        "#{group_id}:#{artifact_id}:#{version}"
      end

      def to_ivy_module_id
        Ivy::ModuleRevisionId.new_instance(group_id, artifact_id, version)
      end
    end

    begin :comparisons
      def <=>(other)
        d = self.group_id <=> other.group_id
        return d unless d == 0
        d = self.artifact_id <=> other.artifact_id
        return d unless d == 0
        d = self.version <=> other.version
        return d
      end

      def eql?(other)
        (self <=> other) == 0
      end

      def hash
        @hash ||= begin
          h = 0
          [group_id, artifact_id, version].each { |p| h = (h & 33554431) * 31 ^ p.hash }
          h
        end
      end
    end
  end
end