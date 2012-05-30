# encoding: utf-8

require 'yaml'
require 'ivy'


module PomPomPom
  class Runner
    def self.run(*args)
      new.run(*args)
    end

    def initialize
      @installer = Installer.new(:repositories => create_repositories)
    end

    def run(*coordinates)
      create_coordinates(coordinates).each do |coordinate|
        @installer.install(coordinate)
      end
    end

  private
    
    def configuration
      @configuration ||= begin
        configuration = {:repositories => {}, :dependencies => []}
        if File.exists?('.pompompom')
          c = YAML.load(File.read('.pompompom'))
          configuration[:repositories] = c['repositories'] if c['repositories']
          configuration[:dependencies] = c['dependencies'] if c['dependencies']
        end
        configuration
      end
    end

    def create_coordinates(coordinates)
      coordinates.map do |coordinate|
        case coordinate
        when MavenCoordinate
          coordinate
        when /^[^:]+:[^:]+:[^:]+$/
          MavenCoordinate.parse(coordinate)
        else
          raise ArgumentError, %("#{coordinate}" could not be converted to a Maven coordinate)
        end
      end.compact
    end

    def create_repositories
      configuration[:repositories].map do |name, url|
        MavenRepository.new(name, url)
      end
    end
  end
end

require 'pompompom/maven_repository'
require 'pompompom/maven_coordinate'
require 'pompompom/installer'