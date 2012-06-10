# encoding: utf-8

require 'yaml'
require 'ivy'


module PomPomPom
  class Runner
    def self.run(*args)
      new.run(*args)
    end

    def initialize(configuration={})
      @configuration = load_configuration(configuration)
      @installer = Installer.new(@configuration)
    end

    def run(*coordinates)
      all_coordinates(coordinates).each do |coordinate|
        @installer.install(coordinate)
      end
    end

  private
    
    def load_configuration(extra_config)
      repositories = {}
      dependencies = []
      destination = 'lib/ext'
      if File.exists?('.pompompom')
        c = YAML.load(File.read('.pompompom'))
        repositories = c['repositories'] if c['repositories']
        dependencies = c['dependencies'] if c['dependencies']
        destination = c['destination'] if c['destination']
      end
      destination = extra_config[:destination] if extra_config[:destination]
      {
        :repositories => create_repositories(repositories.merge(extra_config[:repositories])),
        :dependencies => (dependencies + extra_config[:dependencies]).uniq,
        :install_pattern => File.expand_path("#{destination}/[artifact]-[revision]-[type].[ext]")
      }
    end

    def all_coordinates(extra_coordinates)
      create_coordinates(@configuration[:dependencies] + extra_coordinates)
    end

    def create_coordinates(coordinates)
      coordinates.map do |coordinate|
        case coordinate
        when MavenCoordinate
          coordinate
        when Array
          MavenCoordinate.new(*coordinate)
        when /^[^:]+:[^:]+:[^:]+$/ # TODO: also /^[^#]+#[^;];.+$/
          MavenCoordinate.parse(coordinate)
        else
          raise ArgumentError, %("#{coordinate}" could not be converted to a Maven coordinate)
        end
      end.compact
    end

    def create_repositories(repos)
      repos.map do |name, url|
        MavenRepository.new(name, url)
      end
    end
  end
end

require 'pompompom/maven_repository'
require 'pompompom/maven_coordinate'
require 'pompompom/installer'