require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'fileutils'


module PomPomPom
  describe Resolver do
    before do
      @repository_path = File.expand_path('../../resources/repository', __FILE__)
    end
    
    describe '#download!' do
      before do
        @tmp_dir = File.join(Dir.tmpdir, 'pompompom')
        FileUtils.rm_rf(@tmp_dir)
      end
      
      after do
        FileUtils.rm_rf(@tmp_dir)
      end
      
      context 'setup' do
        before do
          @dependency = Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0')
          @resolver = Resolver.new([@repository_path], :downloader => FilesystemDownloader.new)
        end
        
        it 'creates the target directory' do
          @resolver.download!(@tmp_dir, true, @dependency)
          File.exists?(@tmp_dir).should be_true
        end
        
        it 'does not attempt to create the target directory if it already exists' do
          Dir.mkdir(@tmp_dir)
          expect { @resolver.download!(@tmp_dir, true, @dependency) }.to_not raise_error
        end
        
        it 'complains if the target directory exists but is not a directory' do
          FileUtils.touch(@tmp_dir)
          expect { @resolver.download!(@tmp_dir, true, @dependency) }.to raise_error('Cannot create target directory because it already exists (but is not a directory)')
        end
      end
      
      context 'resolving & downloading' do
        before do
          @dependency = Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0')
          @resolver = Resolver.new([@repository_path], :downloader => FilesystemDownloader.new)
          @resolver.download!(@tmp_dir, true, @dependency)
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
          @resolver = Resolver.new([@repository_path], :downloader => FilesystemDownloader.new)
          @resolver.download!(@tmp_dir, true, @dependency)
        end
        
        it 'honors exclusions' do
          files = Dir[@tmp_dir + '/*.jar'].map { |f| File.basename(f) }.sort
          files.should == %w(amqp-client-1.8.0.jar commons-io-1.2.jar test-exclusions-1.0.jar)
        end
      end
      
      context 'with optionals' do
        before do
          @dependency = Dependency.new('com.example', 'test-optional', '1.0')
          @resolver = Resolver.new([@repository_path], :downloader => FilesystemDownloader.new)
          @resolver.download!(@tmp_dir, true, @dependency)
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
          @resolver = Resolver.new([@repository_path], :logger => @logger, :downloader => FilesystemDownloader.new)
        end
        
        it 'logs each downloaded URL' do
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/com/rabbitmq/amqp-client/1.8.0/amqp-client-1.8.0.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/com/rabbitmq/amqp-client/1.8.0/amqp-client-1.8.0.jar"))
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/commons-cli/commons-cli/1.1/commons-cli-1.1.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/commons-cli/commons-cli/1.1/commons-cli-1.1.jar"))
          @logger.should_receive(:info).with(%(Loading POM from "#{@repository_path}/commons-io/commons-io/1.2/commons-io-1.2.pom"))
          @logger.should_receive(:info).with(%(Loading JAR from "#{@repository_path}/commons-io/commons-io/1.2/commons-io-1.2.jar"))
          @resolver.download!(@tmp_dir, true, @dependency)
        end
      end

      it 'raises an error if a dependency cannot be met' do
        r = Resolver.new([@repository_path], :downloader => FilesystemDownloader.new)
        expect { r.download!(@tmp_dir, true, Dependency.new('foo.bar', 'baz', '3.1.4')) }.to raise_error(Resolver::DependencyNotFoundError)
      end
      
      it 'raises an error if no repositories are given' do
        expect { Resolver.new([]) }.to raise_error(ArgumentError)
      end
    end

    describe '#find_transitive_dependencies' do
      before do
        @resolver = Resolver.new([@repository_path])
      end
      
      it 'returns a list of transitive dependencies' do
        all = @resolver.find_transitive_dependencies(Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0'))
        all_coordinates = all.map(&:to_dependency).map(&:to_s)
        all_coordinates.should have(3).items
        all_coordinates.should include('com.rabbitmq:amqp-client:1.8.0')
        all_coordinates.should include('commons-io:commons-io:1.2')
        all_coordinates.should include('commons-cli:commons-cli:1.1')
      end

      it 'returns a unique list of all transitive dependencies' do
        all = @resolver.find_transitive_dependencies(
          Dependency.new('com.rabbitmq', 'amqp-client', '1.8.0'),
          Dependency.new('commons-cli', 'commons-cli', '1.1')
        )
        all_coordinates = all.map(&:to_dependency).map(&:to_s)
        all_coordinates.should have(3).items
        all_coordinates.should include('com.rabbitmq:amqp-client:1.8.0')
        all_coordinates.should include('commons-io:commons-io:1.2')
        all_coordinates.should include('commons-cli:commons-cli:1.1')
      end
    end
  end
end