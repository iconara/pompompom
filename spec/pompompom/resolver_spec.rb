require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Resolver do
    describe '#download!' do
      before(:all) do
        @repository_path = File.expand_path('../../resources/repository', __FILE__)
        @dependency = Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0')
        @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
        @resolver = Resolver.new([@dependency], [@repository_path])
        FileUtils.rm_rf(@tmp_dir) if File.exists?(@tmp_dir)
        @resolver.download!(@tmp_dir, FilesystemDownloader.new)
      end
      
      after(:all) do
        FileUtils.rm_rf(@tmp_dir)
      end
      
      it 'creates the target directory' do
        File.exists?(@tmp_dir).should be_true
      end
      
      %w(commons-cli-1.1 commons-io-1.2 amqp-client-1.8.0).each do |lib|
        it "downloads #{lib}.jar" do
          file = @tmp_dir + '/' + lib + '.jar'
          IO.read(file).chomp.should == lib
        end
      end
    end
  end
  
  class FilesystemDownloader
    def get(path)
      File.read(path) if File.exists?(path)
    end
  end
end