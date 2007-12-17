class TrackerController < ApplicationController
  
  before_filter :check_required_params, :only => :announce
  before_filter :check_remote_ip
  before_filter :port_allowed?
  before_filter :check_passkey
  
  def announce
    set_vars
    log_vars

    @torrent = Torrent.find(:first, :conditions => ['info_hash = ?', @info_hash])

    if @torrent.nil?
      render_error("Could not find torrent with info_hash: #{@info_hash}"); return
    end
        
    logger.warn "\n\nListing all peers:\n"
    Peer.find(:all).each do |p|
      logger.warn "\t#{p.id} :: #{p.torrent_id} :: #{p.peer_id} ::  Port:#{p.port}"
    end
    logger.warn "\n\n"
    # Find the Peer.  If it's not in the DB yet, create the record.
    @peer = @torrent.peers.find(:first, :conditions => ['peer_id = ?', @peer_id])
    if !@peer
      @peer = Peer.create(:torrent_id     => @torrent.id,
                          :peer_id        => @peer_id,
                          :port           => @port,
                          :passkey        => @passkey,
                          :uploaded       => @uploaded,
                          :downloaded     => @downloaded,
                          :to_go          => @left,
                          :seeder         => @seeder,
                          :agent          => request.env['HTTP_USER_AGENT'])
      logger.warn "\nCreated new Peer: #{@peer.id} (#{@peer.torrent.name})"
      logger.warn "\nConnectable check on: #{@remote_ip}, #{@port}  (#{@remote_ip.class}, #{@port.class})"
      is_connectable = @peer.connectable_check!(@remote_ip, @port)
      @peer.reload if is_connectable
      logger.warn "\nConnectable Check Result: #{is_connectable} (#{@peer.connectable})\n"
    end
    
    if @event
      case @event
      when 'started'
        @torrent.peer_started!(@peer, @remote_ip)
      when 'stopped'
        @torrent.peer_stopped!(@peer, @remote_ip)
      when 'completed'
        @torrent.peer_completed!(@peer, @remote_ip)
      end
    end
    
    @torrent.save!

    # TODO: ratio throttling
    @peer_list = []

    peer_ip_hash = CACHE.get(@torrent.tkey)

    if peer_ip_hash.nil?
      logger.warn "\n\n\tpeer_ip_hash is NIL\n for: #{@torrent.tkey}\n\n"
    else
      logger.warn "\n\n\tpeer_ip_hash = #{peer_ip_hash.inspect}\n\n"
    end
    
    if !peer_ip_hash.nil? && !peer_ip_hash.empty?
      @torrent.connectable_peers.each do |p|
        # Requesuting Peer ID check?
        if p.peer_id == @peer_id
          logger.warn "\n\n\t Found Requesting Peer ID: #{p.id} in Cache (#{@remote_ip}:#{@port}) --- NOT sending to this client\n"
          next
        end
        if !peer_ip_hash.has_key?(p.id)
          logger.warn "\n\n\t WARNING :: CACHE leak.  peer_ip_hash does not have Peer ID: #{p.id}\n\n"
        else
          @hashed_ip = peer_ip_hash[p.id]
          next if (@remote_ip == @hashed_ip) && (@port == p.port)  # Don't send back to itself
          logger.warn "\n\n\t ADDING to @peer_list: #{@hashed_ip}:#{p.port} -- #{p.id} -- #{p.peer_id}"
          @peer_list << {'ip' => @hashed_ip, 'peer id' => p.peer_id, 'port' => p.port}
        end
      end
    end
#    @peer_list = @peer_list.randomize.slice(0, C[:num_max_peers])
    @response = {'interval'   => C[:num_announce_interval_minutes].minutes,
                 'complete'   => @torrent.seeders,
                 'incomplete' => @torrent.leechers,
                 'peers'      => @peer_list }
    
    logger.warn "\nNow sending response: "
    logger.warn "\t#{@response.inspect}\n\n"
    
    update_xfer_stats
    
    render :text => @response.to_bencoding
    return
  end

  def scrape
    @info_hash = params[:info_hash]
    # Do not support site-wide scrape for now...
    if !@info_hash
      render_error("Does not currently support multiple info-hash scraping."); return
    end
    
    hex_hash = @info_hash.unpack('H*')
    
    @torrent = Torrent.find(:first, :conditions => ['info_hash = ?', hex_hash])
    
    if !@torrent
      render_error("Could not find torrent with info_hash: #{hex_hash}"); return
    end
    
    resp = {'files' => {@info_hash => {'complete' => @torrent.times_completed,
                                       'downloaded' => @torrent.leechers,
                                       'incomplete' => @torrent.seeders}}}

    render :text => resp.to_bencoding; return
  end

  private
  
  def update_xfer_stats
    @uploaded_since_last   = [0, @uploaded - @peer.uploaded].max
    @downloaded_since_last = [0, @downloaded - @peer.downloaded].max
    
    #logger.warn "\n\tUploaded Since Last: #{@uploaded_since_last}"
    #logger.warn "\n\tDownloaded Since Last: #{@downloaded_since_last}\n"
    
    unless @uploaded_since_last.zero? && @downloaded_since_last.zero?
      # Only update if there has been a change in number of bytes uploaded/downloaded
      @user.uploaded          += @uploaded_since_last
      @user.uploaded_local    += @uploaded_since_last
      @user.downloaded        += @downloaded_since_last
      @user.downloaded_local  += @downloaded_since_last
      @user.save!
    end
    
    #logger.warn "\n in update_xfer_stats, @peer = #{@peer.inspect} \n"
    
    #logger.warn "\n uploaded, downloaded, left = #{@uploaded}, #{@downloaded}, #{@left} "
    #logger.warn "\n classes = #{@uploaded.class}, #{@downloaded.class}, #{@left.class} "
    
    if (@event != 'stopped') && (@uploaded > 0 || @downloaded > 0)
      @peer = @peer.reload rescue nil
      return if @peer.nil?
      # Update the peer's stats
      @peer.uploaded    = @uploaded
      @peer.downloaded  = @downloaded
      @peer.to_go       = @left
      @peer.save!
    end
    
  end
  
  def log_vars
    logger.warn "\n"
    logger.warn "     info_hash: #{@info_hash}"
    logger.warn "         event: #{@event}" if @event
    logger.warn "       peer_id: #{@peer_id}"
    logger.warn "      uploaded: #{@uploaded}"
    logger.warn "    downloaded: #{@downloaded}"
    logger.warn "          left: #{@left}"
    logger.warn "        seeder: #{@seeder}"
    logger.warn "          port: #{@port}"
    logger.warn "           key: #{@key}"
    logger.warn "     remote IP: #{@remote_ip}"
    logger.warn ""
  end
  
  def set_vars
    
    @rsize = 50
    ['num want', 'numwant', 'num_want'].each do |k|
      if params[k]
        @rsize = params[k].to_i
        break
      end
    end
    @info_hash    = params[:info_hash].unpack('H*')
    @peer_id      = params[:peer_id]
    @uploaded     = params[:uploaded].to_i
    @downloaded   = params[:downloaded].to_i
    @left         = params[:left].to_i
    @key          = params[:key]
    
    @event = params[:event]
    @seeder = (@left == 0) ? true : false
    
  end
  
  def check_required_params
    [:info_hash, :peer_id, :port, :uploaded, :downloaded, :left].each do |p|
      if !params[p]
        render_error("Missing required parameter: #{p.to_s}")
        return false
      end
    end
    return true
  end
  
  def check_remote_ip
    get_remote_ip # See: application.rb
    valid_ip?
  end
  
  def check_passkey
    @passkey = params[:passkey]
    if @passkey.nil?
      render_error("Missing passkey portion of the URL: /tracker/**********/announce"); return false
    end
    
    @user = User.find(:first, :conditions => ["passkey = ?", @passkey])
    if @user.nil?
      render_error("Invalid passkey: #{@passkey}"); return false
    end
  end
  
  def valid_ip?
    return true if RAILS_ENV == 'development'
    @reserved_ips = [ ['0.0.0.0','2.255.255.255'],
                      ['10.0.0.0','10.255.255.255'],
                      ['127.0.0.0','127.255.255.255'],
                      ['169.254.0.0','169.254.255.255'],
                      ['172.16.0.0','172.31.255.255'],
                      ['192.0.2.0','192.0.2.255'],
                      ['192.168.0.0','192.168.255.255'],
                      ['255.255.255.0','255.255.255.255'] ]
    
    @reserved_ips.each do |rips|
      ip_start, ip_end = *rips
      if (@remote_ip >= ip_start) && (@remote_ip <= ip_end)
        render_error("Invalid IP Address: #{@remote_ip}"); return false
      end
    end
    return true
  end
  
  def port_allowed?
    
    @port         = (params[:port] || 0).to_i
    
    @blacklisted_ports = [ [411, 413],    # direct connect
#                           [6881, 6889],  # Official BitTorrent
                           [6346, 6347]]  # gnutella
                           
#    if [0, 1214, 4662, 6699].include?(@port)   # kazaa, emule & winmx
#      render_error("Port not allowed (please use uTorrent or a supported client): #{@remote_ip}"); return false
#    end
    
    @blacklisted_ports.each do |ports|
      p_start, p_end = *ports
      if (@port >= p_start) && (@port <= p_end)
        render_error("Port not allowed (please use uTorrent or a supported client): #{@remote_ip}"); return false
      end
    end
    return true
  end
  
end
