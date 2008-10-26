require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resources/new.html.erb" do
  before(:each) do
    assigns[:resource] = stub_model(Resource,
      :new_record? => true,
      :file_file_name => "value for file_file_name",
      :file_content_type => "value for file_content_type",
      :file_file_size => "1"
    )
  end

  it "should render new form" do
    render "/resources/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", resources_path)
  end
end


