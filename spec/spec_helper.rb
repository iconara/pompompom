$: << File.expand_path('../../lib', __FILE__)

unless defined?(Bundler)
  require 'rubygems'
  require 'bundler'
end

Bundler.setup

require 'pompompom'
