class ScrapeController < ApplicationController
  
  def index
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
  
end
