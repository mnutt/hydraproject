class HomeController < ApplicationController
  before_filter :check_logged_in

  def index
    @active = Torrent.find_by_sql("SELECT torrents.*, (torrents.leechers + torrents.seeders) as active FROM torrents ORDER BY active DESC LIMIT 10")
    @best_seeded = Torrent.find(:all, :order => "seeders DESC", :limit => 100)
    @most_snatched = Torrent.find(:all, :conditions => ["seeders > ? AND times_completed > ?", 0, 0], :order => "times_completed DESC", :limit => 100)
    Torrent.clear_user_ids
  end
  
  def check_logged_in
    return true if user_logged_in?
    flash[:notice] = "#{C[:app_name]} is a private tracker.  Please <a href=\"/account/signup\">Signup</a> or <a href=\"/account/login\">Login</a> to continue."
    redirect_to :controller => :account, :action => :signup
    return false
  end
  
end
