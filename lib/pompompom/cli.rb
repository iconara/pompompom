require 'yaml'


module PomPomPom
  class Cli
    def initialize(stdin, stdout, stderr, options={})
      @config = Config.new(options)
      @config.load!
      @stdin, @stdout, @stderr = stdin, stdout, stderr
      @status_logger = EchoLogger.new(@stderr)
      @downloader = CachingDownloader.new(@config.cache_dir, Downloader.new)
      @resolver = options[:resolver]
    end
    
    def run!(*args)
      if args.empty?
        print_usage
        return 1
      end
      
      resolver = create_resolver
    
      @config.create_file! unless @config.file_exists?
      create_lib_directory!
    
      @status_logger.info("Determining transitive dependencies...")
    
      dependencies = parse_dependencies(args)
      dependencies = resolver.find_transitive_dependencies(*dependencies)
      dependencies = dependencies.reject { |d| File.exists?(File.join(@config.target_dir, d.jar_file_name)) }
    
      if dependencies.empty?
        @status_logger.info('All dependencies are met')
      else
        dependencies.each do |dependency|
          @status_logger.info(%(Downloading "#{dependency.to_dependency.to_s}"))
          resolver.download!(@config.target_dir, false, dependency)
        end
      end
      
      return 0
    rescue => e
      @status_logger.warn(%(Warning: #{e.message}))
      return 1
    end
    
  private
  
    def create_lib_directory!
      return if File.directory?(@config.target_dir)
      raise %(Cannot create destination, "#{@config.target_dir}" is a file!) if File.exists?(@config.target_dir)
      Dir.mkdir(@config.target_dir)
    end
  
    def create_resolver
      @resolver ||= Resolver.new(
        @config.repositories, 
        :logger => @status_logger, 
        :downloader => @downloader
      )
    end
    
    def parse_dependencies(args)
      args.map do |coordinate|
        begin
          Dependency.parse(coordinate)
        rescue ArgumentError => e
          @status_logger.warn(%(Warning: "#{coordinate}" is not a valid artifact coordinate))
          nil
        end
      end.compact
    end
  
    def print_usage
      @status_logger.info('Usage: pompompom <group_id:artifact_id:version> [<group_id:artifact_id:version>]')
    end
    
    class EchoLogger
      def initialize(io)
        @io = io
      end
      
      def debug(msg); end
      
      def info(msg)
        @io.puts(msg)
      end
      
      alias_method :warn, :info
      alias_method :fatal, :info
    end
  end
end