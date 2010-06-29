require 'open-uri'

module PomPomPom
  class Downloader
    def get(url)
      open(url).read
    end
  end
  
  class FilesystemDownloader
    def get(path)
      File.read(path) if File.exists?(path)
    end
  end
end
