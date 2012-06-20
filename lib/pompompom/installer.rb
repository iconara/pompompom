# encoding: utf-8

require 'yaml'
require 'ivy'


module PomPomPom
  class Installer
    def initialize(configuration={})
      @configuration = configuration
    end

    def install(coordinate)
      ivy.install(
        coordinate.to_ivy_module_id, 
        ivy.settings.default_resolver.name, 
        INSTALL_RESOLVER_NAME, 
        install_options(coordinate.attributes)
      )
    end

  private

    INSTALL_RESOLVER_NAME = 'install'.freeze
    DEFAULT_INSTALL_ATTRIBUTES = {
      :overwrite => true,
      :transitive => true,
      :type_filter => 'jar,bundle'.freeze
    }.freeze

    def ivy
      @ivy ||= begin
        ivy = Ivy::Ivy.new_instance
        ivy.configure_default
        ivy.settings.add_resolver(create_install_resolver)
        repositories.each do |repository|
          resolver = repository.to_ivy_resolver
          resolver.settings = ivy.settings
          ivy.settings.default_resolver.add(resolver)
        end
        ivy
      end
    end

    def create_install_resolver
      install_resolver = Ivy::FileSystemResolver.new
      install_resolver.name = INSTALL_RESOLVER_NAME
      install_resolver.add_ivy_pattern(install_pattern)
      install_resolver.add_artifact_pattern(install_pattern)
      install_resolver
    end

    def install_options(attributes)
      attributes = DEFAULT_INSTALL_ATTRIBUTES.merge(attributes)
      install_options = Ivy::InstallOptions.new
      install_options.set_overwrite(attributes[:overwrite])
      install_options.set_transitive(attributes[:transitive])
      install_options.set_artifact_filter(Ivy::FilterHelper.get_artifact_type_filter(attributes[:type_filter]))
      install_options
    end

    def install_pattern
      @configuration[:install_pattern]
    end

    def repositories
      @configuration[:repositories]
    end
  end
end
