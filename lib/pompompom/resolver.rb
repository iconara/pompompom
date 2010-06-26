module PomPomPom
  class Resolver
    class JarNotFoundError < StandardError; end
    class DependencyNotFoundError < StandardError; end
    
    def initialize(dependencies, repositories, options={})
      @dependencies, @repositories, @logger = dependencies, repositories, (options[:logger] || NullLogger.new)
      raise ArgumentError, 'No repositories given!' if repositories.nil? || repositories.empty?
    end
    
    def download!(target_dir, downloader=Downloader.new)
      Dir.mkdir(target_dir)
      resolver = PomResolver.new(@dependencies, @repositories, downloader, @logger)
      resolver.all_poms.each do |pom|
        destination = File.join(target_dir, "#{pom.artifact_id}-#{pom.version}.jar")
        JarDownloader.new(pom, destination, @repositories, downloader, @logger).download!
      end
    end
    
  private
  
    class NullLogger
      def info(msg); end
    end
  
    class PomResolver
      def initialize(dependencies, repositories, downloader, logger)
        @dependencies, @repositories, @downloader, @logger = dependencies, repositories, downloader, logger
      end
      
      def all_poms
        @dependencies.map { |d| resolve_dependencies(d) }.flatten
      end
      
    private
      
      def resolve_dependencies(dependency)
        pom = nil
        @repositories.detect do |repository|
          pom = get_pom(repository, dependency)
          pom
        end
        raise DependencyNotFoundError, "Could not find POM for #{dependency} in any repository" unless pom
        [pom] + (pom.dependencies.map { |d| resolve_dependencies(d) })
      end
      
      def get_pom(repository, dependency)
        url = dependency.pom_url(repository)
        @logger.info(%(Loading POM from "#{url}"))
        data = @downloader.get(url)
        if data
          pom = Pom.new(StringIO.new(data))
          pom.parse!
          pom
        else
          nil
        end
      end
    end
    
    class JarDownloader
      def initialize(pom, local_path, repositories, downloader, logger)
        @pom, @local_path, @repositories, @downloader, @logger = pom, local_path, repositories, downloader, logger
      end
      
      def download!
        data = nil
        @repositories.detect do |repository|
          url = @pom.jar_url(repository)
          @logger.info(%(Loading JAR from "#{url}"))
          data = @downloader.get(url)
          data
        end
        raise JarNotFoundError, "Could not download JAR for #{dependency} in any repository" unless data
        File.open(@local_path, 'w') { |f| f.write(data) }
      end
    end
  end
end