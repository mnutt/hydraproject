class AnnounceController < ApplicationController
  
  before_filter :check_required_params
  before_filter :get_remote_ip

  def index
    set_vars
    log_vars
    @torrent = Torrent.find_by_info_hash(@info_hash) rescue nil
    if @torrent.nil?
      render_error("Could not find torrent with info_hash: #{@info_hash}"); return
    end
    
  end

  private
  
  def log_vars
    logger.warn "     info_hash: #{@info_hash}"
    logger.warn "         event: #{@event}" if @event
    logger.warn "       peer_id: #{@peer_id}"
    logger.warn "      uploaded: #{@uploaded}"
    logger.warn "    downloaded: #{@downloaded}"
    logger.warn "          left: #{@left}"
    logger.warn "        seeder: #{@seeder}"
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
    @left         = params[:left]
    
    @event = params[:event] || ''
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
      if (@remote_ip > ip_start) && (@remote_ip < ip_end)
        render_error("Invalid IP Address: #{@remote_ip}"); return false
      end
    end
    return true
  end
  
end
