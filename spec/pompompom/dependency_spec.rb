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
        s.should == 'net.iconara:pompompom:1.0'
      end
    end

    describe '#eql?' do
      it 'is equal to another dependency with the same group ID, artifact ID and version' do
        d1 = Dependency.new('net.iconara', 'pompompom', '1.0')
        d2 = Dependency.new('net.iconara', 'pompompom', '1.0')
        d1.should == d2
      end

      it 'is not equal to another dependency with another version' do
        d1 = Dependency.new('net.iconara', 'pompompom', '1.0')
        d2 = Dependency.new('net.iconara', 'pompompom', '1.1')
        d1.should_not == d2
      end

      it 'is not equal to another dependency with another group ID' do
        d1 = Dependency.new('net.iconara', 'pompompom', '1.0')
        d2 = Dependency.new('com.example', 'pompompom', '1.0')
        d1.should_not == d2
      end

      it 'is not equal to another dependency with another artifact ID' do
        d1 = Dependency.new('net.iconara', 'pompompom', '1.0')
        d2 = Dependency.new('net.iconara', 'mopmopmop', '1.0')
        d1.should_not == d2
      end
    end

    describe '.parse' do
      it 'parses a Maven coordinate' do
        d = Dependency.parse('net.iconara:pompompom:1.0')
        d.group_id.should == 'net.iconara'
        d.artifact_id.should == 'pompompom'
        d.version.should == '1.0'
      end
      
      it 'parses a Maven coordinate with packaging label' do
        d = Dependency.parse('net.iconara:pompompom:jar:1.0')
        d.group_id.should == 'net.iconara'
        d.artifact_id.should == 'pompompom'
        d.version.should == '1.0'
        d.packaging.should == 'jar'
      end
      
      it 'parses a Maven coordinate with packaging label and classifier' do
        d = Dependency.parse('net.iconara:pompompom:ear:xyz:1.0')
        d.group_id.should == 'net.iconara'
        d.artifact_id.should == 'pompompom'
        d.version.should == '1.0'
        d.packaging.should == 'ear'
        d.classifier.should == 'xyz'
      end
      
      it 'raises an exception if the coordinate is malformed' do
        expect { Dependency.parse('net.iconara:pompompom') }.to raise_error
      end

      it 'raises an exception if the coordinate is empty' do
        expect { Dependency.parse('') }.to raise_error
      end

      it 'raises an exception if the coordinate is nil' do
        expect { Dependency.parse('') }.to raise_error
      end
    end
  end
end