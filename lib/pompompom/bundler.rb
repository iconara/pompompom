# encoding: utf-8

require 'pompompom'


module PomPomPom
  class MavenCoordinateAdapter
    attr_reader :coordinate

    def initialize(coordinate)
      @coordinate = coordinate
    end

    begin :bundler_compatibility
      def source
        nil
      end

      def name
        @name ||= "#@coordinate.group_id:#@coordinate.artifact_id"
      end

      def gem_platforms(valid_platforms)
        if valid_platforms.include?(Gem::Platform::JAVA)
          [Gem::Platform::JAVA] 
        else
          []
        end
      end

      def requirement
        Gem::Requirement.create([])
      end
    end
  end

  class MavenRepositoryAdapter
    attr_reader :repository

    def initialize(repository)
      @repository = repository
    end

    begin :bundler_compatibility
      def specs
        Bundler::Index.new
      end

      def to_lock
        ''
      end
    end
  end

  class ArtifactInstaller
    def initialize(*args)
      @root, @definition = args
      repositories = @definition.mvn_sources.map(&:repository)
      @installer = PomPomPom::Installer.new(:repositories => repositories)
    end

    def run(options)
      coordinates = @definition.mvn_dependencies.map(&:coordinate)
      coordinates.each do |coordinate|
        @installer.install(coordinate)
      end
    end
  end
end

module Bundler
  class Dsl
    def mvn(group, artifact, version)
      @dependencies << PomPomPom::MavenCoordinateAdapter.new(PomPomPom::MavenCoordinate.new(group, artifact, version))
    end

    def mvn_source(url, options={})
      @sources << PomPomPom::MavenRepositoryAdapter.new(PomPomPom::MavenRepository.new(options[:name], url))
    end
  end

  class Definition
    def dependencies
      @dependencies.reject { |d| d.is_a?(PomPomPom::MavenCoordinateAdapter) }
    end

    def mvn_dependencies
      @dependencies.select { |d| d.is_a?(PomPomPom::MavenCoordinateAdapter) }
    end

    def sources
      @sources.reject { |d| d.is_a?(PomPomPom::MavenRepositoryAdapter) }
    end

    def mvn_sources
      @sources.select { |d| d.is_a?(PomPomPom::MavenRepositoryAdapter) }
    end
  end

  class Installer
    class << self
      alias_method :_original_install, :install

      def install(root, definition, options={})
        _original_install(root, definition, options)
        PomPomPom::ArtifactInstaller.new(root, definition).run(options)
      end
    end
  end
end
