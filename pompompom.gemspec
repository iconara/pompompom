Gem::Specification.new do |s|
  s.name        = 'pompompom'
  s.version     = '2.0.0'
  s.platform    = 'java'
  s.authors     = ['Theo Hultberg']
  s.email       = ['theo@iconara.net']
  s.homepage    = 'http://github.com/iconara/pompompom'
  s.summary     = 'Dependency manager for JRuby'
  s.description = 'Painless JAR dependency management for JRuby'

  s.rubyforge_project = 'pompompom'
  
  s.files         = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.executables   = %w[pompompom]
  s.require_paths = %w[lib]
end
