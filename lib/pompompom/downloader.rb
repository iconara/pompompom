require 'open-uri'

module PomPomPom
  class Downloader
    def get(url)
      open(url).read
    end
  end
end
