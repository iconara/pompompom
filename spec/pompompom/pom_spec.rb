require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../url_builders_shared', __FILE__)


module PomPomPom
  describe Pom do
    it_should_behave_like 'an URL builder'
    
    before do
      @url_builder = Pom.new(StringIO.new('<project><groupId>net.iconara</groupId><artifactId>pompompom</artifactId><version>1.0</version><packaging>jar</packaging></project>'))
      @url_builder.parse!
    end
      
    describe '#parse!' do
      context 'when parsing a file' do
        before do
          @example_pom_path = File.expand_path('../../resources/repository/com/rabbitmq/amqp-client/1.8.0/amqp-client-1.8.0.pom', __FILE__)
          @pom = File.open(@example_pom_path, 'r') do |f|
            pom = Pom.new(f)
            pom.parse!
            pom
          end
        end
    
        it('finds the right group ID') { @pom.group_id.should == 'com.rabbitmq' }
        it('finds the right artifact ID') { @pom.artifact_id.should == 'amqp-client' }
        it('finds the right version') { @pom.version.should == '1.8.0' }
        it('finds the right packaging type') { @pom.packaging.should == 'jar' }
        it('finds the right name') { @pom.name.should == 'RabbitMQ Java Client' }
        it('finds the right description') { @pom.description.should == 'RabbitMQ AMQP Java Client' }
        it('finds the right URL') { @pom.url.should == 'http://www.rabbitmq.com' }

        it 'finds two dependencies in the default scope' do
          @pom.dependencies.should have(2).items
        end
      
        it 'finds one dependency in the test scope' do
          @pom.dependencies(:test).should have(1).items
        end
      
        it 'finds a dependency on JUnit' do
          dep = @pom.dependencies(:test).first
          dep.group_id.should == 'junit'
        end
      
        it 'finds a dependency on commons-cli v1.1' do
          dep = @pom.dependencies.select { |d| d.group_id == 'commons-cli' && d.artifact_id == 'commons-cli' && d.version == '1.1' }
          dep.should_not be_empty
        end
      end

      context 'with exclusions' do
        before do
          @example_pom_path = File.expand_path('../../resources/repository/com/example/test-exclusions/1.0/test-exclusions-1.0.pom', __FILE__)
          @pom = File.open(@example_pom_path, 'r') do |f|
            pom = Pom.new(f)
            pom.parse!
            pom
          end
        end
        
        it 'finds exclusions' do
          d = @pom.dependencies.first
          d.exclusions.first.artifact_id.should == 'commons-cli'
        end
      end

      context 'with optional' do
        before do
          @example_pom_path = File.expand_path('../../resources/repository/com/example/test-optional/1.0/test-optional-1.0.pom', __FILE__)
          @pom = File.open(@example_pom_path, 'r') do |f|
            pom = Pom.new(f)
            pom.parse!
            pom
          end
        end
        
        it 'finds exclusions' do
          d = @pom.dependencies.first
          d.should be_optional
        end
      end
    
      context 'when properties are inherited from parent' do
        before do
          p = <<-XML
            <project>
              <parent>
                <groupId>com.example</groupId>
                <artifactId>test-parent</artifactId>
                <version>2.0</version>
              </parent>
              <artifactId>pompompom</artifactId>
              <packaging>jar</packaging>
            </project>
          XML
          @pom = Pom.new(StringIO.new(p))
          @pom.parse!
        end
        
        it 'finds the group ID from the parent specification' do
          @pom.group_id.should == 'com.example'
        end

        it 'finds the version from the parent specification' do
          @pom.version.should == '2.0'
        end
      end
    end
  end
end