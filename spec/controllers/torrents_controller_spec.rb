require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TorrentsController do
  describe "responding to GET download" do
    before do
      @torrent_data = File.open("#{RAILS_ROOT}/spec/data/test.torrent").read
      User.destroy_all
      @torrent = Factory.create(:torrent)
      @user = @torrent.user
      login_as(@user)
      get :download, :id => @torrent.id
    end

    it 'should return a valid torrent' do
      response.body.should =~ /foo.org/
      response.body.should =~ /^d8:announce/
    end
  end
end
