require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resources/show.html.erb" do
  before(:each) do
    assigns[:resource] = @resource = stub_model(Resource,
      :file_file_name => "value for file_file_name",
      :file_content_type => "value for file_content_type",
      :file_file_size => "1"
    )
  end

  it "should render attributes in <p>" do
    render "/resources/show.html.erb"
    response.should have_text(/value\ for\ file_file_name/)
    response.should have_text(/value\ for\ file_content_type/)
    response.should have_text(/1/)
  end
end

