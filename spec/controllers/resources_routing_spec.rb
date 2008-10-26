require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ResourcesController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "resources", :action => "index").should == "/resources"
    end
  
    it "should map #new" do
      route_for(:controller => "resources", :action => "new").should == "/resources/new"
    end
  
    it "should map #show" do
      route_for(:controller => "resources", :action => "show", :id => 1).should == "/resources/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "resources", :action => "edit", :id => 1).should == "/resources/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "resources", :action => "update", :id => 1).should == "/resources/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "resources", :action => "destroy", :id => 1).should == "/resources/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/resources").should == {:controller => "resources", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/resources/new").should == {:controller => "resources", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/resources").should == {:controller => "resources", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/resources/1").should == {:controller => "resources", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/resources/1/edit").should == {:controller => "resources", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/resources/1").should == {:controller => "resources", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/resources/1").should == {:controller => "resources", :action => "destroy", :id => "1"}
    end
  end
end
