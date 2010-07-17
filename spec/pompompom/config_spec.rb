require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Config do
    before do
      @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
      FileUtils.rm_rf(@tmp_dir)
      Dir.mkdir(@tmp_dir)
    end
    
    after do
      FileUtils.rm_rf(@tmp_dir)
    end
    
    context 'defaults' do
      subject { Config.new }
      
      its(:target_dir)   { should == 'lib' }
      its(:repositories) { should == %w(http://repo1.maven.org/maven2) }
      its(:cache_dir)    { should == File.expand_path('~/.pompompom') }
      its(:config_file)  { should == File.expand_path('~/.pompompomrc') }
    end
    
    describe '#load!' do
      it 'loads the config file' do
        config_file = File.join(@tmp_dir, '.pom3rc')
        File.open(config_file, 'w') { |f| f.write(YAML::dump(:repositories => %w(repo1 repo2))) }
        config = Config.new(:config_file => config_file)
        config.load!
        config.repositories.should == %w(repo1 repo2)
      end
    end
    
    describe '#file_exists?' do
      before do
        @config_file = File.join(@tmp_dir, '.pom3rc')
        @config = Config.new(:config_file => @config_file)
      end
      
      it 'returns true if the file exists' do
        FileUtils.touch(@config_file)
        @config.file_exists?.should == true
      end
      
      it 'returns false if the file doesn\'t exist' do
        @config.file_exists?.should == false
      end
    end
    
    describe '#create_file!' do
      before do
        @config_file = File.join(@tmp_dir, '.pom3rc')
        @config = Config.new(:config_file => @config_file)
      end
      
      after do
        FileUtils.rm_f(@config_file)
      end
      
      it 'creates the file and puts the standard repository list in it' do
        @config.create_file!
        YAML.load(File.read(@config_file))['repositories'].should == %w(http://repo1.maven.org/maven2)
      end
      
      it 'doesn\'t clobber existing files' do
        FileUtils.touch(@config_file)
        @config.create_file!
        File.read(@config_file).should == ''
      end
    end
  end
end