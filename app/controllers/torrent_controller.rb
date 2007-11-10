class TorrentController < AuthenticatedController
    
  def browse
    params[:page] ||= 1
    @torrents = Torrent.paginate :order => 'id DESC', :page => params[:page]
  end
  
  def download
    @torrent = Torrent.find(params[:id])
    @meta_info = @torrent.meta_info
    @meta_info.key = current_user.passkey
    @meta_info.announce = URI.parse("#{BASE_URL}tracker/#{current_user.passkey}/announce")
    
    @bencoded = @meta_info.to_bencoding
    logger.warn "\n\nDownload: #{@torrent.id} ::  #{@torrent.filename}\n\n\tBencoding:\n#{@bencoded}\n\n"
    send_data @bencoded, :filename => @torrent.filename, :type => 'application/x-bittorrent'; return
  end
  
  def upload
    if request.post?
      @torrent = Torrent.new(params[:torrent])
      the_file = params[:the_torrent]
      if the_file.nil? || (the_file && the_file.original_filename.blank?)
        flash[:notice] = "Please select a torrent file to upload."
        return false
      end
      
      tmp_path = get_tmp_path(the_file)
      logger.warn "\n#{tmp_path}\n"
      
      File.open(tmp_path, "w") { |f| f.write(the_file.read) }
      if File.exists?(tmp_path)
        # Get the MetaInfo, confirm that it's a legit torrent
        begin
          meta_info = RubyTorrent::MetaInfo.from_location(tmp_path)
        rescue RubyTorrent::MetaInfoFormatError => e
          flash[:notice] = "The uploaded file does not appear to be a valid .torrent file."
          return false
        rescue StandardError => e
          flash[:notice] = "There was an error processing your upload.  Please contact the admins if this problem persists."
          return false
        end

        @torrent.filename = the_file.original_filename
        
        
        info_str = Torrent.dump_metainfo(meta_info)
        
        logger.warn info_str
        
        # First save the torrent so that it gets an ID set
        @torrent.save
        @torrent.set_metainfo!(meta_info)

        @torrent.move!(tmp_path)
        
        @torrent.user = current_user
        @torrent.save!
        flash[:notice] = "Success!  Torrent uploaded."
        @torrent = Torrent.new
      end
      
    else
      @torrent = Torrent.new
    end
  end
  
  def show
    @torrent = Torrent.find(params[:id]) rescue nil
    if @torrent.nil?
      redirect_to :back; return
    end
    @torrent.increment!(:views)
  end
  
  def file_list #AJAX
    @torrent = Torrent.find(params[:id]) rescue nil
    if @torrent.nil?
      render :text => 'Could not find torrent.'; return
    end
    render :layout => false
  end
  
  def destroy #AJAX & ADMIN only
    moderator_required
    @torrent = Torrent.find(params[:id])
    @torrent.destroy
    flash[:notice] = "Torrent removed."
    redirect_to :back; return
  end
  
  private
  
  def get_tmp_path(the_file)
    tmp_path = File.join(RAILS_ROOT, 'tmp', 'uploads', "#{current_user.id}_#{rand(1000)}_#{the_file.original_filename}")
    if File.exist?(tmp_path)
      return get_tmp_path(the_file)
    end
    return tmp_path
  end
  
end
