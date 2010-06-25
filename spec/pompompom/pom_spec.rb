require File.expand_path('../../spec_helper', __FILE__)


module PomPomPom
  describe Pom do
    before do
      @example_pom_path = File.expand_path('../../resources/example.pom', __FILE__)
    end
  
    describe '#parse!' do
      subject do
        File.open(@example_pom_path, 'r') do |f|
          pom = Pom.new(f)
          pom.parse!
          pom
        end
      end
    
      its(:group_id) { should == 'com.rabbitmq' }
      its(:artifact_id) { should == 'amqp-client' }
      its(:version) { should == '1.8.0' }
      its(:packaging) { should == 'jar' }
      its(:name) { should == 'RabbitMQ Java Client' }
      its(:description) { should == 'RabbitMQ AMQP Java Client' }
      its(:url) { should == 'http://www.rabbitmq.com' }

      it 'has two dependencies in the default scope' do
        subject.dependencies.should have(2).items
      end
      
      it 'has one dependency in the test scope' do
        subject.dependencies(:test).should have(1).items
      end
      
      it 'has a dependency on JUnit' do
        dep = subject.dependencies(:test).first
        dep.group_id.should == 'junit'
      end
      
      it 'has a dependency on commons-cli v1.1' do
        dep = subject.dependencies.select { |d| d.group_id == 'commons-cli' && d.artifact_id == 'commons-cli' && d.version == '1.1' }
        dep.should_not be_empty
      end
    end
  end
end