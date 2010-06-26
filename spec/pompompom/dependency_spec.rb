require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../url_builders_shared', __FILE__)


module PomPomPom
  describe Dependency do
    before do
      @url_builder = Dependency.new('net.iconara', 'pompompom', '1.0')
    end
    
    it_should_behave_like 'an URL builder'
    
    describe '#initialize' do
      it 'can be created with named arguments' do
        d = Dependency.new(:group_id => 'net.iconara', :artifact_id => 'pompompom', :version => '1.0')
        d.group_id.should == 'net.iconara'
        d.artifact_id.should == 'pompompom'
        d.version.should == '1.0'
      end
      
      it 'can be created with a regular argument list' do
        d = Dependency.new('net.iconara', 'pompompom', '1.0')
        d.group_id.should == 'net.iconara'
        d.artifact_id.should == 'pompompom'
        d.version.should == '1.0'
      end
    end
    
    describe '#to_s' do
      it 'returns the Maven artifact descriptor' do
        s = Dependency.new('net.iconara', 'pompompom', '1.0').to_s
        s.should == 'net.iconara:pompompom:jar:1.0'
      end
    end
  end
end