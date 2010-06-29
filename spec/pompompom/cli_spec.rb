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
    
    it 'returns 1 if no arguments given' do
      @cli.run!.should == 1
    end
    
    it 'installs any artifacts mentioned on the command line' do
      @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
      @stderr.string.should include('Determining transitive dependencies...')
      @stderr.string.should include('Downloading "net.iconara:pompompom:1.0"')
      @stderr.string.should include('Downloading "com.example:test:9.9"')
    end
    
    it 'returns 0 if all goes well' do
      @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9').should == 0
    end
    
    context 'when artifacts have already been downloaded' do
      before do
        FileUtils.mkdir('lib')
        FileUtils.touch(File.join('lib', 'pompompom-1.0.jar'))
      end
      
      it 'does not download them again' do
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
        @stderr.string.should_not include('Downloading "net.iconara:pompompom:1.0"')
      end
      
      it 'warns if none will be downloaded' do
        FileUtils.touch(File.join('lib', 'test-9.9.jar'))
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
        @stderr.string.should include('All dependencies are met')
      end
      
      it 'returns 0' do
        FileUtils.touch(File.join('lib', 'test-9.9.jar'))
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9').should == 0
      end
    end
    
    it 'complains about malformed artifact coordinates' do
      @cli.run!('net.iconara:pompompom:1.0', 'foobar')
      @stderr.string.should include('Warning: "foobar" is not a valid artifact coordinate')
    end
    
    context 'when "lib" exists but is not a directory' do
      before do
        @cli = Cli.new(@stdin, @stdout, @stderr)
        @cli.stub!(:create_resolver).and_return(@resolver)
        FileUtils.touch(File.join(@tmp_dir, 'lib'))
      end
      
      it 'complains' do
        @cli.run!('com.example:test:9.9')
        @stderr.string.should include('Warning: Cannot create destination, "lib" is a file!')
      end
      
      it 'returns 1' do
        @cli.run!('com.example:test:9.9').should == 1
      end
    end
  end
end