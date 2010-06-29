module PomPomPom
  class Metadata
    def initialize(io)
      @io = io
    end
    
    def parse!
      doc = Hpricot.XML(@io)
      versioning = doc.at('/metadata/versioning')
      if versioning
        release = versioning.at('release/text()')
        if release
          @latest_version = release.to_s
        else
          @latest_version = versioning.search('versions/version/text()').map(&:to_s).sort.last
        end
      else
        @latest_version = doc.at('/metadata/version/text()').to_s
      end
    end
    
    def latest_version
      @latest_version
    end
  end
end