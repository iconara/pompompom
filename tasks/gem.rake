# encoding: utf-8

require 'jeweler'


Jeweler::Tasks.new do |gem|
  gem.name = 'pompompom'
  gem.summary = %Q{Ruby dependency manager for Maven repository artifacts}
  gem.description = %Q{Ruby dependency manager for Maven repository artifacts}
  gem.email = 'theo@iconara.net'
  gem.homepage = 'http://github.com/iconara/pompompom'
  gem.authors = ['Theo Hultberg']
  gem.version = PomPomPom::VERSION
  gem.test_files = FileList['spec/**/*.rb']
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
end

Jeweler::GemcutterTasks.new
