require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResourcesController do

  def mock_resource(stubs={})
    @mock_resource ||= mock_model(Resource, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all resources as @resources" do
      Resource.should_receive(:find).with(:all).and_return([mock_resource])
      login_as(:admin_user)
      get :index
      assigns[:resources].should == [mock_resource]
    end

    describe "with mime type of xml" do
  
      it "should render all resources as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        Resource.should_receive(:find).with(:all).and_return(resources = mock("Array of Resources"))
        resources.should_receive(:to_xml).and_return("generated XML")
        login_as(:admin_user)
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested resource as @resource" do
      Resource.should_receive(:find).with("37").and_return(mock_resource)
      login_as(:admin_user)
      
      get :show, :id => "37"
      assigns[:resource].should equal(mock_resource)
    end
    
    describe "with mime type of xml" do

      it "should render the requested resource as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        Resource.should_receive(:find).with("37").and_return(mock_resource)
        mock_resource.should_receive(:to_xml).and_return("generated XML")
        login_as(:admin_user)
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new resource as @resource" do
      Resource.should_receive(:new).and_return(mock_resource)
      login_as(:admin_user)
      get :new
      assigns[:resource].should equal(mock_resource)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested resource as @resource" do
      Resource.should_receive(:find).with("37").and_return(mock_resource)
      login_as(:admin_user)
      get :edit, :id => "37"
      assigns[:resource].should equal(mock_resource)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      before do
        @request.session[:user_id] = Factory.create(:user).id
      end
      
      it "should expose a newly created resource as @resource" do
        Resource.should_receive(:new).with({'these' => 'params'}).and_return(mock_resource(:save => true))
        mock_resource.should_receive(:user=)
        login_as(:admin_user)
        post :create, :resource => {:these => 'params'}
        assigns(:resource).should equal(mock_resource)
      end

      it "should redirect to the created resource" do
        Resource.stub!(:new).and_return(mock_resource(:save => true))
        mock_resource.should_receive(:user=)
        login_as(:admin_user)
        post :create, :resource => {}
        response.should redirect_to(resource_url(mock_resource))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved resource as @resource" do
        Resource.stub!(:new).with({'these' => 'params'}).and_return(mock_resource(:save => false))
        mock_resource.should_receive(:user=)
        login_as(:admin_user)
        post :create, :resource => {:these => 'params'}
        assigns(:resource).should equal(mock_resource)
      end

      it "should re-render the 'new' template" do
        Resource.stub!(:new).and_return(mock_resource(:save => false))
        mock_resource.should_receive(:user=)
        login_as(:admin_user)
        post :create, :resource => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do
      before do
        login_as(:admin_user)
      end

      it "should update the requested resource" do
        Resource.should_receive(:find).with("37").and_return(mock_resource)
        mock_resource.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :resource => {:these => 'params'}
      end

      it "should expose the requested resource as @resource" do
        Resource.stub!(:find).and_return(mock_resource(:update_attributes => true))
        put :update, :id => "1"
        assigns(:resource).should equal(mock_resource)
      end

      it "should redirect to the resource" do
        Resource.stub!(:find).and_return(mock_resource(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(resource_url(mock_resource))
      end

    end
    
    describe "with invalid params" do
      before do
        login_as(:admin_user)
      end

      it "should update the requested resource" do
        Resource.should_receive(:find).with("37").and_return(mock_resource)
        mock_resource.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :resource => {:these => 'params'}
      end

      it "should expose the resource as @resource" do
        Resource.stub!(:find).and_return(mock_resource(:update_attributes => false))
        put :update, :id => "1"
        assigns(:resource).should equal(mock_resource)
      end

      it "should re-render the 'edit' template" do
        Resource.stub!(:find).and_return(mock_resource(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do
    before do
      login_as(:admin_user)
    end

    it "should destroy the requested resource" do
      Resource.should_receive(:find).with("37").and_return(mock_resource)
      mock_resource.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the resources list" do
      Resource.stub!(:find).and_return(mock_resource(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(resources_url)
    end

  end

end
