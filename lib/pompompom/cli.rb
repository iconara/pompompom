require 'yaml'


module PomPomPom
  class Cli
    STANDARD_REPOSITORIES = %w(http://repo1.maven.org/maven2)
    DEFAULT_DESTINATION_DIR = 'lib'
    CACHE_DIR = File.expand_path('~/.pompompom')
    CONFIG_FILE = File.expand_path('~/.pompompomrc')
    
    def initialize(stdin, stdout, stderr)
      @stdin, @stdout, @stderr = stdin, stdout, stderr
      @status_logger = EchoLogger.new(@stderr)
      @downloader = CachingDownloader.new(CACHE_DIR, Downloader.new)
    end
    
    def run!(*args)
      if args.empty?
        print_usage
        return 1
      end
      
      resolver = create_resolver
    
      create_config_file!
      create_lib_directory!
    
      @status_logger.info("Determining transitive dependencies...")
    
      dependencies = parse_dependencies(args)
      dependencies = resolver.find_transitive_dependencies(*dependencies)
      dependencies = dependencies.reject { |d| File.exists?(File.join(destination_dir_path, d.jar_file_name)) }
    
      if dependencies.empty?
        @status_logger.info('All dependencies are met')
      else
        dependencies.each do |dependency|
          @status_logger.info(%(Downloading "#{dependency.to_dependency.to_s}"))
          resolver.download!(destination_dir_path, false, dependency)
        end
      end
      
      return 0
    rescue => e
      @status_logger.warn(%(Warning: #{e.message}))
      return 1
    end
    
  private
  
    def create_config_file!
      return if File.exists?(config_file_path)
      File.open(config_file_path, 'w') { |f| f.write(YAML.dump('repositories' => STANDARD_REPOSITORIES))}
    end
  
    def create_lib_directory!
      return if File.directory?(destination_dir_path)
      raise %(Cannot create destination, "#{destination_dir_path}" is a file!) if File.exists?(destination_dir_path)
      Dir.mkdir(destination_dir_path)
    end
  
    def create_resolver
      Resolver.new(
        config[:repositories], 
        :logger => @status_logger, 
        :downloader => @downloader
      )
    end
    
    def config
      @config ||= symbolize_keys(YAML.load(File.read(config_file_path)))
    end
    
    def symbolize_keys(h)
      h.keys.inject({}) do |acc, k|
        acc[k.to_sym] = if Hash === h[k] then symbolize_keys(h[k]) else h[k] end
        acc
      end
    end
    
    def config_file_path
      CONFIG_FILE
    end
    
    def destination_dir_path
      DEFAULT_DESTINATION_DIR
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