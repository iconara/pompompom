module PomPomPom
  class Cli
    STANDARD_REPOSITORIES = [
      'http://repo1.maven.org/maven2/'
    ]
    
    DEFAULT_DESTINATION_DIR = 'lib'
    
    def initialize(stdin, stdout, stderr)
      @stdin, @stdout, @stderr = stdin, stdout, stderr
    end
    
    def run!(*args)
      if args.empty?
        print_usage
        1
      else
        resolver = create_resolver
        
        create_lib_directory!
        
        @stdout.puts("Determining transitive dependencies...")
        
        dependencies = parse_dependencies(args)
        dependencies = resolver.find_transitive_dependencies(*dependencies)
        dependencies = dependencies.reject { |d| File.exists?(File.join(DEFAULT_DESTINATION_DIR, d.jar_file_name)) }
        
        if dependencies.empty?
          @stdout.puts(%(All dependencies are met))
        else
          dependencies.each do |dependency|
            @stdout.puts(%(Downloading "#{dependency.to_dependency.to_s}"))
            resolver.download!(DEFAULT_DESTINATION_DIR, false, dependency)
          end
        end
      end
      0
    end
    
  private
  
    def create_lib_directory!
      return if File.directory?(DEFAULT_DESTINATION_DIR)
      raise %(Cannot create destination, "#{DEFAULT_DESTINATION_DIR}" is a file!) if File.exists?(DEFAULT_DESTINATION_DIR)
      Dir.mkdir(DEFAULT_DESTINATION_DIR)
    end
  
    def create_resolver
      Resolver.new(STANDARD_REPOSITORIES)
    end
  
    def parse_dependencies(args)
      args.map do |coordinate|
        begin
          Dependency.parse(coordinate)
        rescue ArgumentError => e
          @stderr.puts(%(Warning: "#{coordinate}" is not a valid artifact coordinate))
          nil
        end
      end.compact
    end
  
    def print_usage
      @stderr.puts('Usage: pompompom <group_id:artifact_id:version> [<group_id:artifact_id:version>]')
    end
  end
end