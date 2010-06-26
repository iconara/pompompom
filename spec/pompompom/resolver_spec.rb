require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Resolver do
    describe '#download!' do
      before do
        @repository_path = File.expand_path('../../resources/repository', __FILE__)
        @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
        FileUtils.rm_rf(@tmp_dir)
      end
      
      after do
        FileUtils.rm_rf(@tmp_dir)
      end
      
      context 'resolving & downloading' do
        before do
          @dependency = Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0')
          @resolver = Resolver.new([@dependency], [@repository_path])
          @resolver.download!(@tmp_dir, FilesystemDownloader.new)
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

      context 'with exclusions' do
        before do
          @dependency = Dependency.new('com.example', 'test-exclusions', '1.0')
          @resolver = Resolver.new([@dependency], [@repository_path])
          @resolver.download!(@tmp_dir, FilesystemDownloader.new)
        end
        
        it 'honors exclusions' do
          files = Dir[@tmp_dir + '/*.jar'].map { |f| File.basename(f) }.sort
          files.should == %w(amqp-client-1.8.0.jar commons-io-1.2.jar test-exclusions-1.0.jar)
        end
      end
      
      context 'with optionals' do
        before do
          @dependency = Dependency.new('com.example', 'test-optional', '1.0')
          @resolver = Resolver.new([@dependency], [@repository_path])
          @resolver.download!(@tmp_dir, FilesystemDownloader.new)
        end
        
        it 'doesn\'t download optional dependencies' do
          files = Dir[@tmp_dir + '/*.jar'].map { |f| File.basename(f) }.sort
          files.should == %w(test-optional-1.0.jar)
        end
      end
      
      context 'logging' do
        before do
          @dependency = Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0')
          @logger = double()
          @resolver = Resolver.new([@dependency], [@repository_path], :logger => @logger)
        end
        
        it 'logs each downloaded URL' do
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/com/rabbitmq/amqp-client/1.8.0/amqp-client-1.8.0.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/com/rabbitmq/amqp-client/1.8.0/amqp-client-1.8.0.jar"))
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/commons-cli/commons-cli/1.1/commons-cli-1.1.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/commons-cli/commons-cli/1.1/commons-cli-1.1.jar"))
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/commons-io/commons-io/1.2/commons-io-1.2.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/commons-io/commons-io/1.2/commons-io-1.2.jar"))
          @resolver.download!(@tmp_dir, FilesystemDownloader.new)
        end
      end

      it 'raises an error if a dependency cannot be met' do
        r = Resolver.new([Dependency.new('net.iconara', 'pompompom', '1.0')], [@repository_path])
        expect { r.download!(@tmp_dir, FilesystemDownloader.new) }.to raise_error(Resolver::DependencyNotFoundError)
      end
      
      it 'raises an error if no repositories are given' do
        expect { Resolver.new([Dependency.new('net.iconara', 'pompompom', '1.0')], []) }.to raise_error(ArgumentError)
      end
    end
  end
  
  class FilesystemDownloader
    def get(path)
      File.read(path) if File.exists?(path)
    end
  end
end