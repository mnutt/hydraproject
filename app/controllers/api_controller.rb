class ApiController < ApplicationController
  
  before_filter :authenticate
  before_filter :set_vars
  
  def time
    render :text => "<time>#{Time.now}</time>", :status => 200; return
  end
  
  def echo_data
    render :text => @data; return
  end
  
  def list_users
    if @first_load
      @users = User.find(:all, :conditions => ['is_admin = ?', false])  # Do not send admin accounts
    else
      if @since < 0
        since_required; return
      end
      @users = User.find(:all, :conditions => ['is_admin = ? AND created_at < ?', false, Time.now.ago(@since)])
    end
    render :template => 'api/list_users', :layout => false; return
  end
  
  def list_transfer_stats
    if @first_load
      @users = User.find(:all, :conditions => ['is_admin = ?', false])  # Do not send admin accounts
    else
      if @since_sync < 0
        render_error(:since_sync_required, "Missing required param since_sync")
      end
      
      @users = User.find(:all, :conditions => ['is_admin = ? AND created_at < ?', false, Time.now.ago(@since)])
    end
    render :template => 'api/list_users', :layout => false; return
  end
  
  def list_torrents
    if @first_load
      @torrents = Torrent.find :all
    else
      if @since < 0
        since_required; return
      end
      @torrents = Torrent.find(:all, :conditions => ["created_at < ?", Time.now.ago(@since)])
    end
    render :template => 'api/get_torrents', :layout => false; return
  end
  
  def get_torrent
    @info_hash = params[:info_hash] || ''
    @torrent = Torrent.find(:all, :conditions => ["info_hash = ?", @info_hash])
    if @torrent.nil?
      render_error(:not_found, "Torrent not found.  Passed info_hash: #{@info_hash}")
    end
    
    @meta_info = @torrent.meta_info
    @meta_info.announce = URI.parse("#{BASE_URL}tracker")
    
    @bencoded = @meta_info.to_bencoding
    logger.warn "\n\nDownload: #{@torrent.id} ::  #{@torrent.filename}\n\n\tBencoding:\n#{@bencoded}\n\n"
    send_data @bencoded, :filename => @torrent.filename, :type => 'application/x-bittorrent'; return
  end
  
  private
  
  def set_vars
    @response.headers["Content-Type"] = "application/xml"
    @first_load   = params[:first_load]
    @data         = params[:data]
    @since        = (params[:since] || -1).to_i  # time ago in seconds
    @since_sync   = (params[:since_sync] || -1).to_i  # key
  end
  
  def since_required
    render_error(:since_required, "Missing required param 'since' -- time ago in seconds that the query should be restricted to.")
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
