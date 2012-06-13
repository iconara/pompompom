$: << 'lib'

require 'pompompom/version'


task :release do
  version_string = "v#{PomPomPom::VERSION}"
  unless %x(git tag -l).include?(version_string)
    system %(git tag -a #{version_string} -m #{version_string})
  end
  system %(gem build pompompom.gemspec && gem push pompompom-*.gem && mv pompompom-*.gem pkg)
end