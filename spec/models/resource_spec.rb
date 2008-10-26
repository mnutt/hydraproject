require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Resource do
  before(:each) do
    @user = User.create(:email => "foo@example.com", :login => "login", :password => "password", :password_confirmation => "password")
    @valid_attributes = {
      :file_file_name => "value for file_file_name",
      :file_content_type => "value for file_content_type",
      :file_file_size => "1",
      :user => @user,
      :file_updated_at => Time.now,
    }
  end

  it "should create a new instance given valid attributes" do
    resource = Resource.new(@valid_attributes)
    resource.should_receive(:generate_torrent)
    resource.save!
  end
end
