require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/resources/edit.html.erb" do
  before(:each) do
    assigns[:resource] = @resource = stub_model(Resource,
      :new_record? => false,
      :file_file_name => "value for file_file_name",
      :file_content_type => "value for file_content_type",
      :file_file_size => "1"
    )
  end

  it "should render edit form" do
    render "/resources/edit.html.erb"
    
    response.should have_tag("form[action=#{resource_path(@resource)}][method=post]") do
      with_tag('input#resource_file_file_name[name=?]', "resource[file_file_name]")
      with_tag('input#resource_file_content_type[name=?]', "resource[file_content_type]")
      with_tag('input#resource_file_file_size[name=?]', "resource[file_file_size]")
    end
  end
end


