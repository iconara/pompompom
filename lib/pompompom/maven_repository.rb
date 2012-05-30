# encoding: utf-8

module PomPomPom
  class MavenRepository
    attr_reader :name, :url

    def initialize(name, url)
      @url = url
      @name = name
      @name = @url[%r{^https?://([^:/]+).*$}, 1] unless @name
    end

    def to_ivy_resolver
      resolver = Ivy::IBiblioResolver.new
      resolver.name = @name
      resolver.root = @url
      resolver.set_m2compatible(true)
      resolver
    end
  end
end