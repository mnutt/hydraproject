class TorrentController < ApplicationController
  include ApplicationHelper
  
  before_filter :check_logged_in, :except => [:download]
  
  def browse
    params[:page] ||= 1
    @in_category = false
    @categories = []
    @title = "Browse Torrents"
    if params[:cat]
      @in_category = true
      @category = Category.find(params[:cat])
      @categories = [@category.id]
      @title = "Browse Torrents &raquo; #{@category.name}"
      @torrents = Torrent.paginate(:conditions => ["category_id = ?", @category.id], :order => 'created_at DESC', :page => params[:page])
    elsif params[:categories] && !params[:query]
      @in_category = true
      @categories = params[:categories].keys
      @torrents = Torrent.paginate(:conditions => ["category_id IN (?)", @categories], :order => 'created_at DESC', :page => params[:page])
    elsif params[:query]
      @in_category = true
      @in_search = true
      @query = params[:query]
      @title = "Search &raquo; #{@query}"
      if params[:categories]
        @categories = params[:categories].keys
        conditions = ["match(name,filename,description) against (?) AND category_id IN (?)", @query, @categories]
      else
        conditions = ["match(name,filename,description) against (?)", @query]
      end
      @torrents = Torrent.paginate(:conditions => conditions, :order => 'created_at DESC', :page => params[:page])
    else
      @torrents = Torrent.paginate :order => 'id DESC', :page => params[:page]
    end
    
    @page_title = "Browse Latest (page #{params[:page]})"
  end
  
  def download
    if params[:passkey]
      user = User.find(:first, :conditions => ["passkey = ?", params[:passkey]])
      if user.nil?
        check_logged_in; return false
      else
        set_current_user(user)
      end
    else
      if !user_logged_in?
        check_logged_in; return false
      end
    end
    @torrent = Torrent.find(params[:id])
    @meta_info = @torrent.meta_info
    @meta_info.key = current_user.passkey # || params[:passk
    @announce_url = URI.parse("#{BASE_URL}tracker/#{current_user.passkey}/announce")
    @meta_info.announce = @announce_url

    # Here's where the announce-list magic happens
    # Set not only this announce URL, but announce URLs for all trackers in the federation
    @announce_urls = [@announce_url]
    TRUSTED_SITES.each do |site|
      announce_url = site[:announce_url].gsub('{{passkey}}', current_user.passkey)
      # IMPORTANT - each 'announce_url' must be enclosed in an Array.
      #    See: http://wiki.depthstrike.com/index.php/P2P:Protocol:Specifications:Multitracker
      #    And: http://bittornado.com/docs/multitracker-spec.txt
      #
      # When there are multiple announce_urls in the first tier (i.e. all in a single array), then clients will simply
      #   shuffle that array and connect to the first random announce_url.
      #
      # Instead, what we want is for the torrent client to connect to *ALL* of the trackers.
      #
      @announce_urls << URI.parse(announce_url)
    end
    #puts "\n\n #{@announce_list.inspect}\n\n"
    @announce_list = @announce_urls.collect { |url| [url] }
    @meta_info.announce_list = @announce_list
    @bencoded = @meta_info.to_bencoding
    #logger.warn "\n\nDownload: #{@torrent.id} ::  #{@torrent.filename}\n\n\tBencoding:\n#{@bencoded}\n\n"
    send_data @bencoded, :filename => @torrent.filename, :type => 'application/x-bittorrent'; return
  end
  
  def upload
    @page_title = "Upload"
    @categories = Category.find(:all, :order => 'name ASC')
    
    if request.post?
      @torrent = Torrent.new(params[:torrent])
      the_file = params[:the_torrent]

      if the_file.nil?
        flash[:notice] = "Please select a torrent file to upload."
        return false
      end
      
      if the_file.is_a?(String)
        # CASE: Safari
        tmp_path = File.join(RAILS_ROOT, 'tmp', 'uploads', "#{current_user.id}_#{rand(100000)}.torrent")
        contents = the_file
        original_filename = (@torrent.name && !@torrent.name.blank?) ? "#{@torrent.name.guidify}.torrent" : 'unknown.torrent'
      else
        # CASE: all other sane browsers
        tmp_path = get_tmp_path(the_file)
        contents = the_file.read
        original_filename = the_file.original_filename
      end
      
      #logger.warn "\n#{tmp_path}\n"
      File.open(tmp_path, "w") { |f| f.write(contents) }

      if File.exists?(tmp_path)
        # Get the MetaInfo, confirm that it's a legit torrent
        begin
          meta_info = RubyTorrent::MetaInfo.from_location(tmp_path)
        rescue RubyTorrent::MetaInfoFormatError => e
          flash[:notice] = "The uploaded file does not appear to be a valid .torrent file."
          return false
        rescue StandardError => e
          flash[:notice] = "There was an error processing your upload: #{$!}.  Please contact the admins if this problem persists."
          return false
        end

        @torrent.filename = original_filename
        
        
        info_str = Torrent.dump_metainfo(meta_info)
        
        logger.warn info_str
        
        # First save the torrent so that it gets an ID set
        @torrent.save
        @torrent.set_metainfo!(meta_info)
        
        # Check for existing torrents with this info_hash, that are, you know, *NOT* this torrent
        existing = Torrent.find(:first, :conditions => ["id != ? AND info_hash = ?", @torrent.id, @torrent.info_hash])
        if existing
          File.unlink(tmp_path) rescue nil
          flash[:notice] = "A torrent with this info_hash already exists: #{torrent_dl(existing)}<br/><br/>Please seed this torrent instead of uploading a new one."
          @torrent.destroy
          redirect_to :action => 'upload'; return
        else
          @torrent.move!(tmp_path)

          @torrent.user = current_user
          @torrent.save!
          flash[:notice] = "Success!  Torrent uploaded."
          @torrent = Torrent.new
        end
        
      end
      
    else
      @torrent = Torrent.new
    end
  end
  
  def show
    @torrent = Torrent.find(:first, :conditions => ["torrents.id = ?", params[:id]], :include => :category) rescue nil
    if @torrent.nil?
      redirect_to :back; return
    end
    @torrent.increment!(:views)
    @comments = Comment.paginate(:conditions => ["torrent_id = ?", @torrent.id], :order => 'id ASC', :page => params[:page])
    @page_title = @torrent.name
  end
  
  def file_list #AJAX
    @torrent = Torrent.find(params[:id]) rescue nil
    if @torrent.nil?
      render :text => 'Could not find torrent.'; return
    end
    render :layout => false
  end
  
  verify :only=>:destroy, :method=>:post
  
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
