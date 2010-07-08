require 'open-uri'
require 'fileutils'
require 'uri'


module PomPomPom
  class Downloader
    def get(url)
      open(url).read
    end
  end
  
  class FilesystemDownloader
    def get(path)
      raise %(Cannot read "#{path}": No such file) unless File.exists?(path)
      File.read(path)
    end
  end
  
  class CachingDownloader
    def initialize(cache_dir, downloader=Downloader.new)
      @cache_dir, @downloader = cache_dir, downloader
    end
    
    def get(url)
      cached = cache_path(url)
      if File.exists?(cached)
        File.read(cached)
      else
        data = @downloader.get(url)
        FileUtils.mkdir_p(File.dirname(cached))
        File.open(cached, 'w') { |f| f.write(data) }
        data
      end
    end
    
  private
  
    def cache_path(url)
      uri = URI.parse(url)
      path_components = uri.path.sub(%r{^/}, '').split('/')
      path = File.join(@cache_dir, uri.host, *path_components)
      path
    end
  end
end
