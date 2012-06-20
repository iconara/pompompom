require_relative '../spec_helper'


module PomPomPom
  describe MavenCoordinate do
    describe '.parse' do
      it 'correctly parses a standard Maven coordinate' do
        coordinate = MavenCoordinate.parse('org.jruby:jruby-complete:1.6.7')
        coordinate.group_id.should == 'org.jruby'
        coordinate.artifact_id.should == 'jruby-complete'
        coordinate.version.should == '1.6.7'
      end

      it 'has no attributes by default' do
        coordinate = MavenCoordinate.parse('org.jruby:jruby-complete:1.6.7')
        coordinate.attributes.should be_empty
      end

      it 'parses the PomPomPom extended coordinate format' do
        coordinate = MavenCoordinate.parse('org.jruby:jruby-complete:1.6.7|transitive=true,overwrite=false')
        coordinate.attributes[:transitive].should be_true
        coordinate.attributes[:overwrite].should be_false
      end
    end
  end
end