class FeedController < ApplicationController
  before_filter { C[:enable_rss] }
  requires_authentication :using => Proc.new{ |username, passkey| @user = User.feed_auth(username, passkey) },
                          :realm => "#{C[:app_name]} Feeds"
                           
  def index
    @title = "#{C[:app_name]} RSS Feed - Latest Torrents"
    @description = "Latest torrents uploaded to the #{C[:app_name]} private tracker."
    @torrents = Torrent.find(:all, :limit => C[:num_items_per_page], :order => 'id DESC')
    render :layout => false
  end
  
end
