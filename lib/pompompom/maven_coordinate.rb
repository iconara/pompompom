# encoding: utf-8

module PomPomPom
  class MavenCoordinate
    attr_reader :group_id, :artifact_id, :version, :attributes

    def self.parse(str)
      coordinate, attrs = str.split('|')
      attributes = parse_attributes(attrs)
      gid, aid, v = coordinate.split(':')
      new(gid, aid, v, attributes)
    end

    def initialize(*args)
      @group_id, @artifact_id, @version, @attributes = args
      @attributes ||= {}
    end

    begin :conversions
      def self.parse_attributes(attrs)
        return {} unless attrs
        pairs = attrs.split(',').map { |a| k, v = a.split('='); [k, v] }
        pairs.map! do |k, v|
          vv = begin
            case v
            when 'true' then true
            when 'false' then false
            else v
            end
          end
          [k.to_sym, vv]
        end
        Hash[pairs]
      end

      def to_s
        str = "#{group_id}:#{artifact_id}:#{version}"
        unless attributes.empty?
          attrs = attributes.map { |k, v| "#{k}=#{v}" }.join(',')
          str << "|#{attrs}"
        end
        str
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