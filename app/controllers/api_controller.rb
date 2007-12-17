class ApiController < ApplicationController
  
  before_filter :authenticate
  before_filter :set_vars
  before_filter :allowed_method_check
  
  AllowedMethods = ['time', 'list_users', 'list_transfer_stats', 'list_torrents', 'get_torrent']

  def index
    # By here, it's passed the 'allowed_method_check' -- so this should be safe:
    send(@method); return
  end
  
  def time
    render :text => "<time>#{Time.now}</time>", :status => 200; return
  end
  
  def echo_data
    render :text => @data; return
  end
  
  def list_users
    if @first_load
      # Do not send admin accounts; only send accounts created locally
      @users = User.find(:all, :conditions => ['is_admin = ? AND is_local = ?', false, true])
    else
      if @since < 0
        since_required; return
      end
      @users = User.find(:all, :conditions => ['is_admin = ? AND is_local = ? AND created_at > ?', false, true, Time.now.ago(@since)])
    end
    render :template => 'api/list_users', :layout => false; return
  end
  
  def list_transfer_stats
    if @first_load
      @users = User.find(:all, :conditions => ['is_admin = ?', false])  # Do not send admin accounts
      next_id = RatioSync.next_id(@domain)
      next_id = (next_id.nil?) ? 1 : next_id + 1
      @current_sync = RatioSync.create!(:domain => @domain, :sync_id => next_id)
      @snapshots = []
      @diffshots = []  # Used by the rxml
      @users.each do |u|
        @snapshots << RatioSnapshot.create!(:ratio_sync_id => @current_sync.sync_id, :user_id => u.id, :login => u.login, :downloaded => u.downloaded_local, :uploaded => u.uploaded_local)
        @diffshots << {:login => u.login, :downloaded => u.downloaded_local, :uploaded => u.uploaded_local}
      end
    else
      @last_sync = RatioSync.find(:first, :conditions => ["sync_Id = ?", @last_sync_id])
      if @last_sync.nil?
        render_error(:since_sync_required, "Could not find last sync with last_sync_id: #{params[:last_sync_id]}"); return
      elsif (@domain != @last_sync.domain)
        render_error(:sync_id_domain_mismatch, "The ID for the sync that you passed (#{params[:last_sync_id]}) does not correspond to the requesting site's domain: #{@domain}"); return
      end
      @users = User.find(:all, :conditions => ['is_admin = ?', false])  # Do not send admin accounts
      @user_hash = {}
      @users.collect {|u| @user_hash[u.id] = u }
      
      @diffshots = []  # Used by the rxml
      @last_sync.ratio_snapshots.each do |rs|
        u = rs.user
        logger.warn "\n\n !!! User: #{u.login}"
        logger.warn "\t u.downloaded_local: #{@user_hash[rs.user_id].downloaded_local}, rs.downloaded: #{rs.downloaded}"
        dl_diff = @user_hash[rs.user_id].downloaded_local - rs.downloaded 
        logger.warn "\t dl_diff: #{dl_diff}"
        dl_diff = 0 if dl_diff < 0  # Cannot go down since last time...
        ul_diff = @user_hash[rs.user_id].uploaded_local - rs.uploaded 
        ul_diff = 0 if ul_diff < 0  # Cannot go down since last time...

        @diffshots << {:login => u.login, :downloaded => dl_diff, :uploaded => ul_diff}
      end
      
      # Now create a *NEW* Sync (the current one for this transaction)
      
      @current_sync = RatioSync.create!(:domain => @domain, :sync_id => RatioSync.next_id(@domain))
      @users.each do |u|
        RatioSnapshot.create!(:ratio_sync_id => @current_sync.id, :user_id => u.id, :login => u.login, :downloaded => u.downloaded_local, :uploaded => u.uploaded_local)
      end
      
    end
    render :template => 'api/list_transfer_stats', :layout => false; return
  end
  
  def list_torrents
    if @first_load
      @torrents = Torrent.find :all
    else
      if @since < 0
        since_required; return
      end
      @torrents = Torrent.find(:all, :conditions => ["created_at > ?", Time.now.ago(@since)], :include => :category)
    end
    render :template => 'api/list_torrents', :layout => false; return
  end
  
  def get_torrent
    @info_hash = params[:info_hash] || ''
    @torrent = Torrent.find(:first, :conditions => ["info_hash = ?", @info_hash], :include => :category)
    if @torrent.nil?
      render_error(:not_found, "Torrent not found.  Passed info_hash: #{@info_hash}"); return
    end
    
    @meta_info = @torrent.meta_info
    @meta_info.announce = URI.parse("#{BASE_URL}tracker")
    
    @bencoded = @meta_info.to_bencoding
    logger.warn "\n\nDownload: #{@torrent.id} ::  #{@torrent.filename}\n\n\tBencoding:\n#{@bencoded}\n\n"
    send_data @bencoded, :filename => @torrent.filename, :type => 'application/x-bittorrent'; return
  end
  
  private
  
  def allowed_method_check
    @method = (params[:method] || '').strip
    unless AllowedMethods.include?(@method)
      render_error(:invalid_method, "Invalid method called ('#{@method}').  Must be one of: #{AllowedMethods.to_sentence}")
      return false
    end
    return true
  end
  
  def set_vars
    response.headers["Content-Type"] = "application/xml"
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
      if @passkey == site[:passkey]
        @site = site
        @domain = site[:domain]
        if site[:ip_required]
          # Also check IP
          @ip = get_remote_ip
          # Let through localhost -- TODO: investigate this more
          return true if '127.0.0.0' == @ip
          return true if site[:ip_required] == @ip
          # Otherwise DENY access
          render_error(:auth_failed, "Authentication failed. Invalid IP Address.")
          return false
        end
        return true 
      end
    end
    render_error(:auth_failed, "Authentication failed.  Invalid passkey param: #{@passkey}")
    return false
  end
  
end
