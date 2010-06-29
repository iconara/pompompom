module PomPomPom
  module UrlBuilder
    def jar_url(repository_url)
      file_url(repository_url, 'jar')
    end
    
    def pom_url(repository_url)
      file_url(repository_url, 'pom')
    end
    
    def file_url(repository_url, type)
      file_name = "#{artifact_id}-#{version}.#{type}"
      "#{append_slash(repository_url)}#{group_path}/#{artifact_id}/#{version}/#{file_name}"
    end
    
    def jar_file_name
      "#{artifact_id}-#{version}.jar"
    end
    
    def metadata_url(repository_url)
      "#{append_slash(repository_url)}#{group_path}/#{artifact_id}/maven-metadata.xml"
    end
    
    def append_slash(repository_url)
      if repository_url[-1,1] == '/'
        repository_url
      else
        repository_url + '/' 
      end
    end
    
    def group_path
      group_id.split('.').join('/')
    end
  end
end
    