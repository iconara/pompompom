$: << File.expand_path('../lib', __FILE__)

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup(:default, :development, :test)

require 'pompompom'

task :default => :spec

Dir[File.join(File.dirname(__FILE__), 'tasks', '*.rake')].each { |t| load t }