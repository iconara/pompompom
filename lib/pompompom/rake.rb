require 'pompompom'


module PomPomPom
  module Rake
    class SimpleLogger
      def initialize(io)
        @io = io
      end
      def info(msg)
        @io.puts(msg)
      end
    end
  
    class NullLogger
      def info(msg); end
    end
  
    def pompompom(*args)
      options = (Hash === args.last) ? args.pop : { }
      dependencies = args.flatten
    
      logger = NullLogger.new
    
      if options[:logger]
        if options[:logger].respond_to?(:info)
          logger = options[:logger]
        elsif options[:logger].respond_to?(:puts)
          logger = SimpleLogger.new(options[:logger])
        end
      end
    
      config = Config.new(options)
      config.load!
    
      downloader   = options[:downloader]
      downloader ||= CachingDownloader.new(config.cache_dir, Downloader.new)
    
      resolver     = Resolver.new(config.repositories, :downloader => downloader)
      dependencies = dependencies.map { |d| Dependency.parse(d) }
      dependencies = resolver.find_transitive_dependencies(*dependencies)
      dependencies = dependencies.reject { |d| File.exists?(File.join(config.target_dir, d.jar_file_name)) }
  
      unless dependencies.empty?
        dependencies.each do |dependency|
          logger.info("Loading #{dependency.jar_file_name}")
          resolver.download!(config.target_dir, false, dependency)
        end
      end
    end
  end
end

include PomPomPom::Rake