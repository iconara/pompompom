require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Cli do
    before do
      @repository_path = File.expand_path('../../resources/repository', __FILE__)
      @stdin  = StringIO.new
      @stdout = StringIO.new
      @stderr = StringIO.new
      @downloader = FilesystemDownloader.new
      @resolver = Resolver.new([@repository_path])
      @cli = Cli.new(@stdin, @stdout, @stderr)
      @cli.stub!(:create_resolver).and_return(@resolver)
      @cli.stub!(:create_lib_directory!)
      @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
      FileUtils.rm_rf(@tmp_dir)
      Dir.mkdir(@tmp_dir)
      Dir.chdir(@tmp_dir)
    end
    
    after do
      FileUtils.rm_rf(@tmp_dir)
    end
    
    it 'prints usage if no arguments given' do
      @cli.run!
      @stderr.string.should include('Usage: pompompom <group_id:artifact_id:version> [<group_id:artifact_id:version>]')
    end
    
    it 'installs any artifacts mentioned on the command line' do
      @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
      @stdout.string.should include('Determining transitive dependencies...')
      @stdout.string.should include('Downloading "net.iconara:pompompom:1.0"')
      @stdout.string.should include('Downloading "com.example:test:9.9"')
    end
    
    it 'does not download artifacts have already been downlowed' do
      FileUtils.mkdir('lib')
      FileUtils.touch(File.join('lib', 'pompompom-1.0.jar'))
      @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
      @stdout.string.should_not include('Downloading "net.iconara:pompompom:1.0"')
    end
    
    it 'warns if no dependencies will be downloaded' do
      FileUtils.mkdir('lib')
      FileUtils.touch(File.join('lib', 'pompompom-1.0.jar'))
      FileUtils.touch(File.join('lib', 'test-9.9.jar'))
      @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
      @stdout.string.should include('All dependencies are met')
    end
    
    it 'complains about malformed artifact coordinates' do
      @cli.run!('net.iconara:pompompom:1.0', 'foobar')
      @stderr.string.should include('Warning: "foobar" is not a valid artifact coordinate')
    end
    
    it 'complains if "lib" exists but is not a directory' do
      @cli = Cli.new(@stdin, @stdout, @stderr)
      @cli.stub!(:create_resolver).and_return(@resolver)
      FileUtils.touch(File.join(@tmp_dir, 'lib'))
      expect { @cli.run!('com.example:test:9.9') }.to raise_error('Cannot create destination, "lib" is a file!')
    end
  end
end