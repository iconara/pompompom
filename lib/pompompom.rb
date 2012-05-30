# encoding: utf-8

require 'yaml'
require 'ivy'


module PomPomPom
  class Runner
    def self.run(*args)
      new.run(*args)
    end

    def run(*args)
      configure!
      install_dependencies!(args.select { |a| a =~ /^[^:]+:[^:]+:[^:]+$/ })
    end

    def install(artifact)
      ivy.install(
        parse_module_id(artifact), 
        ivy.settings.default_resolver.name, 
        INSTALL_RESOLVER_NAME, 
        install_options
      )
    end

  private
    
    INSTALL_PATTERN = 'lib/ext/[module]-[artifact]-[revision].[ext]'.freeze
    INSTALL_RESOLVER_NAME = 'install'.freeze

    def configure!
      if File.exists?('.pompompom')
        @configuration = YAML.load(File.read('.pompompom'))
        @configuration['repositories'] ||= {}
        @configuration['dependencies'] ||= []
        @configuration['repositories'].each do |name, url|
          ivy.settings.add_resolver(create_maven_resolver(name, url, ivy.settings))
        end
      else
        @configuration = {'repositories' => {}, 'dependencies' => []}
      end
    end

    def configuration
      @configuration
    end

    def install_dependencies!(extra_dependencies)
      all_dependencies = (configuration['dependencies'] + extra_dependencies).uniq
      all_dependencies.each do |artifact|
        install(artifact)
      end
    end

    def create_maven_resolver(name, url, settings)
      resolver = Ivy::IBiblioResolver.new
      resolver.name = name
      resolver.root = url
      resolver.settings = settings
      resolver.set_m2compatible(true)
      resolver
    end

    def ivy
      @ivy ||= begin
        ivy = Ivy::Ivy.new_instance
        ivy.configure_default
        ivy.settings.add_resolver(install_resolver)
        ivy
      end
    end

    def install_resolver
      @install_resolver ||= begin
        install_resolver = Ivy::FileSystemResolver.new
        install_resolver.name = INSTALL_RESOLVER_NAME
        install_resolver.add_ivy_pattern(File.expand_path(INSTALL_PATTERN))
        install_resolver.add_artifact_pattern(File.expand_path(INSTALL_PATTERN))
        install_resolver
      end
    end

    def install_options
      @install_options ||= begin
        install_options = Ivy::InstallOptions.new
        install_options.set_overwrite(true)
        install_options
      end
    end

    def parse_module_id(artifact)
      Ivy::ModuleRevisionId.new_instance(*artifact.split(':'))
    end
  end
end