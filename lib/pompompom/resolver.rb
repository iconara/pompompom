module PomPomPom
  class Resolver
    def initialize(dependencies, repositories)
      @dependencies, @repositories = dependencies, repositories
    end
    
    def download!(target_dir, downloader=Downloader.new)
      Dir.mkdir(target_dir)
      poms = @dependencies.map { |d| resolve_dependencies(d, downloader) }.flatten
      poms.each do |pom|
        destination = File.join(target_dir, "#{pom.artifact_id}-#{pom.version}.jar")
        data = nil
        @repositories.detect do |repository|
          url  = dependency_url(repository, pom, 'jar')
          data = downloader.get(url)
          data
        end
        raise "Could not download JAR for #{dependency.group_id}/#{dependency.artifact_id}/#{dependency.version}" unless data
        File.open(destination, 'w') do |f|
          f.write(data)
        end
      end
    end
    
  private
  
    def resolve_dependencies(dependency, downloader)
      pom = nil
      @repositories.detect do |repository|
        pom = get_pom(repository, dependency, downloader)
        pom
      end
      raise "Could not find POM for #{dependency.group_id}/#{dependency.artifact_id}/#{dependency.version}" unless pom
      [pom] + (pom.dependencies.map { |d| resolve_dependencies(d, downloader) })
    end
    
    def get_pom(repository, dependency, downloader)
      url = dependency_url(repository, dependency)
      data = downloader.get(url)
      if data
        pom = Pom.new(StringIO.new(data))
        pom.parse!
        pom
      else
        nil
      end
    end
    
    def dependency_url(repository, dependency, type='pom')
      group_path = dependency.group_id.split('.').join('/')
      file_name = "#{dependency.artifact_id}-#{dependency.version}.#{type}"
      "#{repository}/#{group_path}/#{dependency.artifact_id}/#{dependency.version}/#{file_name}"
    end
  end
end