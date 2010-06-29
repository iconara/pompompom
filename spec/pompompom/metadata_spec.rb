require File.expand_path('../../spec_helper', __FILE__)


module PomPomPom
  describe Metadata do
    before do
      @metadata1 = File.open(File.expand_path('../../resources/repository/aopalliance/aopalliance/maven-metadata.xml', __FILE__), 'r') do |f|
        md = Metadata.new(f)
        md.parse!
        md
      end
      @metadata2 = File.open(File.expand_path('../../resources/repository/com/example/test/maven-metadata.xml', __FILE__), 'r') do |f|
        md = Metadata.new(f)
        md.parse!
        md
      end
      @metadata3 = File.open(File.expand_path('../../resources/repository/com/example/test-abc/maven-metadata.xml', __FILE__), 'r') do |f|
        md = Metadata.new(f)
        md.parse!
        md
      end
    end
    
    describe '#latest_version' do
      it 'returns the latest version when there is only one' do
        @metadata1.latest_version.should == '1.0'
      end
      
      it 'returns the last version' do
        @metadata2.latest_version.should == '9.9'
      end
      
      it 'returns the release version when one is specified' do
        @metadata3.latest_version.should == '1.0'
      end
    end
  end
end