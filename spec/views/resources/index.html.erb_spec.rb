require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resources/index.html.erb" do
  before(:each) do
    assigns[:resources] = [
      stub_model(Resource,
        :file_file_name => "value for file_file_name",
        :file_content_type => "value for file_content_type",
        :file_file_size => "1"
      ),
      stub_model(Resource,
        :file_file_name => "value for file_file_name",
        :file_content_type => "value for file_content_type",
        :file_file_size => "1"
      )
    ]
  end

  it "should render list of resources" do
    render "/resources/index.html.erb"
    response.should have_tag("tr>td", "value for file_file_name", 2)
    response.should have_tag("tr>td", "value for file_content_type", 2)
    response.should have_tag("tr>td", "1", 2)
  end
end

