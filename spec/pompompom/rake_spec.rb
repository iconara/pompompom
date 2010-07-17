require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


describe 'rake' do
  before do
    @repository_path = File.expand_path('../../resources/repository', __FILE__)
    @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
    FileUtils.rm_rf(@tmp_dir)
    Dir.mkdir(@tmp_dir)
    @lib_dir = File.join(@tmp_dir, 'lib')
    @repo_dir = File.join(@tmp_dir, 'repo')
    @config_file = File.join(@tmp_dir, '.pompompomrc')
    @downloader = FilesystemDownloader.new
    @dependencies = %w(com.rabbitmq:amqp-client:1.8.0 com.google.inject:guice:2.0)
  end
  
  after do
    FileUtils.rm_rf(@tmp_dir)
  end
  
  it 'downloads dependencies' do
    pompompom(@dependencies, :target_dir => @lib_dir, :downloader => @downloader, :repositories => [@repository_path], :config_file => @config_file)
    jars = Dir[File.join(@lib_dir, '*.jar')].map { |f| File.basename(f) }
    jars.should include('amqp-client-1.8.0.jar') 
    jars.should include('guice-2.0.jar')
  end
  
  it 'downloads dependencies (when specified as separate arguments)' do
    pompompom('com.rabbitmq:amqp-client:1.8.0', 'com.google.inject:guice:2.0', :target_dir => @lib_dir, :downloader => @downloader, :repositories => [@repository_path], :config_file => @config_file)
    jars = Dir[File.join(@lib_dir, '*.jar')].map { |f| File.basename(f) }
    jars.should include('amqp-client-1.8.0.jar') 
    jars.should include('guice-2.0.jar')
  end

  it 'reads the config file' do
    File.open(@config_file, 'w') { |f| f.write(YAML.dump('repositories' => [@repository_path])) }
    pompompom(@dependencies, :config_file => @config_file, :target_dir => @lib_dir, :downloader => @downloader)
    jars = Dir[File.join(@lib_dir, '*.jar')].map { |f| File.basename(f) }
    jars.should include('amqp-client-1.8.0.jar') 
    jars.should include('guice-2.0.jar')
  end
end