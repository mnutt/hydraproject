class AnnounceController < ApplicationController
  
  before_filter :check_required_params
  before_filter :get_remote_ip
  before_filter :port_allowed?
  
  def index
    set_vars
    log_vars

    @torrent = Torrent.find(:first, :conditions => ['info_hash = ?', @info_hash])

    if @torrent.nil?
      render_error("Could not find torrent with info_hash: #{@info_hash}"); return
    end
    logger.warn "\n\nListing all peers:\n"
    Peer.find(:all).each do |p|
      logger.warn "\t#{p.id} :: #{p.torrent_id} :: #{p.peer_id} ::  #{p.ip}:#{p.port}"
    end
    logger.warn "\n\n"
    # Find the Peer.  If it's not in the DB yet, create the record.
    @peer = @torrent.peers.find(:first, :conditions => ['peer_id = ?', @peer_id])
    if !@peer
      @peer = Peer.create(:torrent_id     => @torrent.id,
                          :peer_id        => @peer_id,
                          :ip             => @remote_ip,
                          :port           => @port,
                          :passkey        => @key,
                          :uploaded       => @uploaded,
                          :downloaded     => @downloaded,
                          :to_go          => @left,
                          :seeder         => @seeder,
                          :agent          => request.env['HTTP_USER_AGENT'])
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
      @torrent.peers.reload.each do |p|
        if p.peer_id == @peer_id
          logger.warn "\n\n\t Found Requesting Peer ID: #{p.id} in Cache (#{p.ip}:#{p.port}) --- NOT sending to this client\n"
          next
        end
        if !peer_ip_hash.has_key?(p.id)
          logger.warn "\n\n\t WARNING :: CACHE leak.  peer_ip_hash does not have Peer ID: #{p.id}\n\n"
        else
          logger.warn "\n\n\t ADDING to @peer_list: #{peer_ip_hash[p.id]}:#{p.port} -- #{p.id} -- #{p.peer_id}"
          @peer_list << {'ip' => peer_ip_hash[p.id], 'peer id' => p.peer_id, 'port' => p.port}
        end
      end
    end
    
    @response = {'interval' => 20,
                 'complete' => @torrent.seeders,
                 'incomplete' => @torrent.leechers,
                 'peers' => @peer_list }
    
    logger.warn "\nNow sending response: "
    logger.warn "\t#{@response.inspect}\n\n"
    render :text => @response.to_bencoding
    return
  end

  private
  
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
  
  def get_remote_ip
    e = request.env
    @remote_ip = e['HTTP_X_FORWARDED_FOR'] || e['HTTP_CLIENT_IP'] || e['REMOTE_ADDR'] || nil
    if @remote_ip.nil?
      render_error("Could not determine remote IP Address."); return false
    end
    return valid_ip?
  end
  
  def valid_ip?
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
                           
    if [1214, 4662, 6699].include?(@port)   # kazaa, emule & winmx
      render_error("Port not allowed (please use uTorrent or a supported client): #{@remote_ip}"); return false
    end
    
    @blacklisted_ports.each do |ports|
      p_start, p_end = *ports
      if (@port >= p_start) && (@port <= p_end)
        render_error("Port not allowed (please use uTorrent or a supported client): #{@remote_ip}"); return false
      end
    end
    return true
  end
  
end
