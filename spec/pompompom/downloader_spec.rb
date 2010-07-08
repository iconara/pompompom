require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Downloader do
    it 'downloads the given URL' do
      Downloader.new.get('http://iconara.net/').should_not be_nil
    end
    
    it 'raises an error if the URL cannot be found' do
      expect { Downloader.new.get('http://example.com/test') }.to raise_error
    end
  end
  
  describe FilesystemDownloader do
    it 'reads a file' do
      FilesystemDownloader.new.get('/etc/hosts').should_not be_nil
    end
    
    it 'raises an error if the file cannot be found' do
      expect { FilesystemDownloader.new.get('/plink') }.to raise_error
    end
  end
  
  describe CachingDownloader do
    before do
      @tmp_dir = File.join(Dir.tmpdir, 'pompompom_cache')
      FileUtils.rm_rf(@tmp_dir)
    end
    
    after do
      FileUtils.rm_rf(@tmp_dir)
    end
    
    it 'creates the directory if it does not exist' do
      CachingDownloader.new(@tmp_dir, stub(:get => 'DATA!')).get('http://example.com/')
      File.directory?(@tmp_dir).should be_true
    end
    
    it 'delegates downloading to another downloader' do
      @wrapped_downloader = stub()
      @wrapped_downloader.should_receive(:get).with('http://example.com/')
      CachingDownloader.new(@tmp_dir, @wrapped_downloader).get('http://example.com/')
    end
    
    it 'only downloads a URL once (same instance)' do
      @wrapped_downloader = stub()
      @wrapped_downloader.stub(:get).with('http://example.com/some/path/to/a/file.json').once.and_return('DATA!')
      @downloader = CachingDownloader.new(@tmp_dir, @wrapped_downloader)
      @downloader.get('http://example.com/some/path/to/a/file.json').should == 'DATA!'
      @downloader.get('http://example.com/some/path/to/a/file.json').should == 'DATA!'
    end
    
    it 'only downloads a URL once (different instances)' do
      @wrapped_downloader = stub()
      @wrapped_downloader.stub(:get).with('http://example.com/some/path/to/a/file.json').once.and_return('DATA!')
      CachingDownloader.new(@tmp_dir, @wrapped_downloader).get('http://example.com/some/path/to/a/file.json').should == 'DATA!'
      CachingDownloader.new(@tmp_dir, @wrapped_downloader).get('http://example.com/some/path/to/a/file.json').should == 'DATA!'
    end
  end
end