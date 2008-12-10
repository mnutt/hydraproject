class FeedController < ApplicationController
  before_filter { C[:enable_rss] }
  before_filter :authorize_download
                           
  def index
    @title = "#{C[:app_name]} RSS Feed - Latest Torrents"
    @description = "Latest torrents uploaded to the #{C[:app_name]} private tracker."
    @torrents = Torrent.find(:all, :limit => C[:num_items_per_page], :order => 'id DESC')
    render :layout => false
  end
  
end
