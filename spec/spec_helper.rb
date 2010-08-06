$: << File.expand_path('../../lib', __FILE__)

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup(:default, :test)

require 'pompompom'
require 'pompompom/cli'
require 'pompompom/rake'
