require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'
require 'yaml'


module PomPomPom
  describe Cli do
    before do
      @repository_path = File.expand_path('../../resources/repository', __FILE__)
      @stdin  = StringIO.new
      @stdout = StringIO.new
      @stderr = StringIO.new
      @downloader = FilesystemDownloader.new
      @resolver = Resolver.new([@repository_path])
      @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
      FileUtils.rm_rf(@tmp_dir)
      Dir.mkdir(@tmp_dir)
      Dir.chdir(@tmp_dir)
      @config_file_path = File.join(@tmp_dir, '.pompompomrc')
      @cli = Cli.new(@stdin, @stdout, @stderr, :resolver => @resolver, :config_file => @config_file_path)
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

    context 'config file' do
      it 'creates the config file if it doesn\'t exist' do
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
        File.exists?(@config_file_path).should be_true
      end
      
      it 'adds the standard repositories to the config file, if it doesn\'t exist' do
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
        @config = YAML.load(File.read(@config_file_path))
        @config['repositories'].should == Config::REPOSITORIES
      end
      
      it 'doesn\'t clobber an existing config file' do
        @config = {'repositories' => %w(http://example.com/repo1 http://example.com/repo2)}
        File.open(@config_file_path, 'w') { |f| f.write(YAML::dump(@config)) }
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
        @config = YAML.load(File.read(@config_file_path))
        @config['repositories'].should == %w(http://example.com/repo1 http://example.com/repo2)
      end
      
      it 'reads the config file' do
        @config = {'repositories' => %w(http://example.com/repo1 http://example.com/repo2)}
        File.open(@config_file_path, 'w') { |f| f.write(YAML::dump(@config)) }
        Resolver.should_receive(:new).with(%w(http://example.com/repo1 http://example.com/repo2), an_instance_of(Hash))
        @cli = Cli.new(@stdin, @stdout, @stderr, :config_file => @config_file_path)
        @cli.run!('net.iconara:pompompom:1.0', 'com.example:test:9.9')
      end
    end
  end
end