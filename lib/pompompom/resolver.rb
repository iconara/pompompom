module PomPomPom
  class Resolver
    class JarNotFoundError < StandardError; end
    class DependencyNotFoundError < StandardError; end
    
    def initialize(repositories, options={})
      @repositories, @logger, @downloader = repositories, (options[:logger] || NullLogger.new), (options[:downloader] || Downloader.new)
      raise ArgumentError, 'No repositories given!' if repositories.nil? || repositories.empty?
    end
    
    def download!(target_dir, transitive, *dependencies)
      create_target_directory(target_dir)
      all_dependencies = if transitive then find_transitive_dependencies(*dependencies) else dependencies end
      all_dependencies.each do |pom|
        destination = File.join(target_dir, "#{pom.artifact_id}-#{pom.version}.jar")
        JarDownloader.new(pom, destination, @repositories, @downloader, @logger).download!
      end
    end
    
    def find_transitive_dependencies(*dependencies)
      resolver = PomResolver.new(dependencies, @repositories, @downloader, @logger)
      filter_newest(group_by_artifact(resolver.all_poms))
    end
    
  private
  
    def filter_newest(pom_groups)
      pom_groups.map do |id, poms|
        if poms.size > 1
          newest = poms.sort { |a, b| a.version <=> b.version }.reverse.first
          @logger.warn(%(Warning: multiple versions of #{id} were required, using the newest required version (#{newest.version})))
          newest
        else
          poms.first
        end
      end.flatten
    end
  
    def group_by_artifact(poms)
      poms.inject({}) do |acc, pom|
        id = "#{pom.group_id}:#{pom.artifact_id}"
        acc[id] ||= []
        acc[id] << pom
        acc
      end
    end
  
    def create_target_directory(target_dir)
      return if File.directory?(target_dir)
      raise 'Cannot create target directory because it already exists (but is not a directory)' if File.exists?(target_dir)
      Dir.mkdir(target_dir)
    end
  
    def args_and_options(*args)
      if Hash === args.last
        options = args.pop
      end
      [args, options || {}]
    end
  
    class NullLogger
      def debug(msg); end
      def info(msg); end
      def warn(msg); end
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
          if dependency.has_version?
            d = dependency
          else
            d = find_latest(dependency, repository)
          end
          pom = get_pom(repository, d)
          pom
        end
        raise DependencyNotFoundError, "Could not find POM for #{dependency} in any repository" unless pom
        transitive_dependencies = pom.dependencies.reject do |d|
          d.optional? || dependency.exclusions.any? { |dd| dd.artifact_id == d.artifact_id }
        end
        [pom] + transitive_dependencies.map { |d| resolve_dependencies(d) }
      end
      
      def find_latest(dependency, repository)
        @logger.info(%(Finding latest version for #{dependency.group_id}:#{dependency.artifact_id}))
        url = dependency.metadata_url(repository)
        metadata = Metadata.new(@downloader.get(url))
        metadata.parse!
        dependency.clone(:version => metadata.latest_version)
      rescue => e
        @logger.warn(%(Could not donwload "#{url}": #{e.message}))
      end
      
      def get_pom(repository, dependency)
        url = dependency.pom_url(repository)
        @logger.debug(%(Loading POM from "#{url}"))
        data = @downloader.get(url)
        if data
          pom = Pom.new(StringIO.new(data))
          pom.parse!
          if pom.has_parent?
            parent = get_pom(repository, pom.parent)
            pom = pom.merge(parent)
          end
          pom
        else
          nil
        end
      rescue => e
        @logger.debug(%(Could not download "#{url}": #{e.message}))
        nil
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
          @logger.debug(%(Loading JAR from "#{url}"))
          begin
            data = @downloader.get(url)
          rescue => e
            @logger.debug(%(Could not download "#{url}": #{e.message}))
          end
          data
        end
        raise JarNotFoundError, "Could not download JAR for #{@pom.to_dependency} in any repository" unless data
        File.open(@local_path, 'w') { |f| f.write(data) }
      end
    end
  end
end