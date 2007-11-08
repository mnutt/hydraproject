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
      
      @last_sync = RatioSync.create!(:domain => @domain)
      @snapshots = []
      @diffshots = []  # Used by the rxml
      @users.each do |u|
        @snapshots << RatioSnapshot.create!(:ratio_sync_id => @last_sync.id, :user_id => u.id, :login => u.login, :downloaded => u.downloaded_local, :uploaded => u.uploaded_local)
        @diffshots << {:login => u.login, :downloaded => u.downloaded_local, :uplaoded => u.uploaded_local}
      end
    else
      @last_sync = RatioSync.find(@last_sync_id)
      if @last_sync.nil?
        render_error(:since_sync_required, "Could not find last sync with last_sync_id: #{params[:last_sync_id]}")
      elsif (@domain != @last_sync.domain)
        render_error(:sync_id_domain_mismatch, "The ID for the sync that you passed (#{params[:last_sync_id]}) does not correspond to the requesting site's domain: #{@domain}")
      end
      @users = User.find(:all, :conditions => ['is_admin = ?', false])  # Do not send admin accounts
      @user_hash = {}
      @users.collect {|u| @user_hash[u.id] = u }
      
      @diffshots = []  # Used by the rxml
      @last_sync.ratio_snapshots.each do |rs|
        dl_diff = @user_hash[rs.user_id].downloaded_local - rs.downloaded 
      	dl_diff = 0 if dl_diff < 0  # Cannot go down since last time...
        ul_diff = @user_hash[rs.user_id].uploaded_local - rs.uploaded 
      	ul_diff = 0 if ul_diff < 0  # Cannot go down since last time...

      	@diffshots << {:login => u.login, :downloaded => u.dl_diff, :uplaoded => u.ul_diff}
      end
      
      # Now create a *NEW* @last_sync that is really the current sync
      @last_sync = RatioSync.create!(:domain => @domain)
      @users.each do |u|
        RatioSnapshot.create!(:ratio_sync_id => @last_sync.id, :user_id => u.id, :login => u.login, :downloaded => u.downloaded_local, :uploaded => u.uploaded_local)
      end
      
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
    @last_sync_id = (params[:last_sync_id] || -1).to_i  # key
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
