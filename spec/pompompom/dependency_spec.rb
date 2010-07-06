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

    describe '#has_version?' do
      it 'is true if version is unspecified' do
        d = Dependency.new(:group_id => 'com.example', :artifact_id => 'test')
        d.should_not have_version
      end
      
      it 'is false if version is set' do
        d = Dependency.new(:group_id => 'com.example', :artifact_id => 'test', :version => '0.0.1')
        d.should have_version
      end
    end
    
    describe '#same_artifact?' do
      it 'returns true if the group and artifact IDs are the same' do
        d1 = Dependency.new(:group_id => 'com.example', :artifact_id => 'hello', :version => '3')
        d2 = Dependency.new(:group_id => 'com.example', :artifact_id => 'hello', :version => '4')
        d1.same_artifact?(d2).should be_true
      end

      it 'returns false if the group and artifact IDs are the same' do
        d1 = Dependency.new(:group_id => 'com.elpmaxe', :artifact_id => 'hello', :version => '3')
        d2 = Dependency.new(:group_id => 'com.example', :artifact_id => 'hello', :version => '3')
        d1.same_artifact?(d2).should_not be_true
      end
    end
    
    describe '#clone' do
      it 'creates an identical copy' do
        d1 = Dependency.new(:group_id => 'com.example', :artifact_id => 'test', :version => '0.0.1')
        d2 = d1.clone
        d1.should == d2
      end
      
      it 'creates an identical copy, save for overridden properties' do
        d1 = Dependency.new(:group_id => 'com.example', :artifact_id => 'test', :version => '0.0.1', :classifier => 'foo')
        d2 = d1.clone(:version => '1.0.0')
        d1.should_not == d2
        d2.group_id.should == 'com.example'
        d2.artifact_id.should == 'test'
        d2.classifier.should == 'foo'
        d2.version.should == '1.0.0'
      end
    end
  end
end