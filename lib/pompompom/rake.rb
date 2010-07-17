require 'pompompom'


module PomPomPom
  def pompompom(*args)
    options = (Hash === args.last) ? args.pop : { }
    dependencies = args.flatten
    
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
        resolver.download!(config.target_dir, false, dependency)
      end
    end
  end
end

include PomPomPom