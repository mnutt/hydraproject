class ApiController < ApplicationController
  
  before_filter :authenticate
  before_filter :set_vars
  
  def time
    render :text => "<time>#{Time.now}</time>", :status => 200 and return
  end
  
  def echo_data
    render :text => @data; return
  end
  
  def get_users
  end
  
  def get_torrents
    if @first_load
      @torrents = Torrent.find :all
    else
#      require_since
      @torrents = Torrent.find(:all, :conditions => ["created_at < ?", Time.now.ago(@since)])
    end
  end
  
  private
  
  def set_vars
    @first_load   = params[:first_load]
    @data         = params[:data]
    @since        = params[:since]  # time ago in seconds
  end
  
  def render_error(code, reason)
    @xml = "<request><response_code>#{code.to_s}</response_code><reason>#{reason}</reason></request>"
    render :text => @xml, :status => 403
  end
  
  def authenticate
    @passkey = params[:passkey]
    TRUSTED_SITES.each do |site|
      if @passkey == site['passkey']
        @site = site
        @domain = site['domain']
        return true 
      end
    end
    render_error(:auth_failed, "Authentication failed.  Invalid passkey param: #{@passkey}")
    return false
  end
  
end
