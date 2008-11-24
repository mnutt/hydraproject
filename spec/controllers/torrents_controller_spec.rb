require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TorrentsController do
  describe "responding to GET download" do
    before do
      @torrent = Factory.create(:torrent)
      login_as(:user)
      get :download, :id => @torrent.id
    end

    it 'should return a valid torrent' do
      response.body.should == "hi"
    end
  end
end
