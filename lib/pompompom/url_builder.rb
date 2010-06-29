module PomPomPom
  module UrlBuilder
    def jar_url(repository_url)
      file_url(repository_url, 'jar')
    end
    
    def pom_url(repository_url)
      file_url(repository_url, 'pom')
    end
    
    def file_url(repository_url, type)
      group_path = group_id.split('.').join('/')
      file_name = "#{artifact_id}-#{version}.#{type}"
      repository_url += '/' unless repository_url[-1,1] == '/'
      "#{repository_url}#{group_path}/#{artifact_id}/#{version}/#{file_name}"
    end
    
    def jar_file_name
      "#{artifact_id}-#{version}.jar"
    end
  end
end
    