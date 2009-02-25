require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Feed do
  before(:each) do
    @valid_attributes = {
      :url => "value for url",
      :user_id => "1"
    }
  end

  it "should create a new instance given valid attributes" do
    Feed.create!(@valid_attributes)
  end
end

describe Feed, "refreshing" do
  before(:each) do
    @feed = Factory.create(:feed)
  end

  it "should generate resources" do
    lambda {
      @feed.refresh
    }.should change(Resource, :count).by(3)
    resource = @feed.resources.first
    resource.file_file_size.should_not be_zero
    resource.file_file_name.should == "episode3.mp3"
  end
end
