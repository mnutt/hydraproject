class TorrentsController < ApplicationController
  include ApplicationHelper
  verify :only=>:destroy, :method=>:post
  before_filter :login_required, :except => [:show, :browse]
  
  def index
    respond_to do |format|
      format.html do
        @torrents = Torrent.paginate :order => 'id DESC', :page => params[:page]
      end
      format.xml do
        if @user = User.feed_auth(params[:user], params[:passkey])
          @title = "#{C[:app_name]} RSS Feed - Latest Torrents"
          @description = "Latest torrents uploaded to the #{C[:app_name]} private tracker."
          @torrents = Torrent.find(:all, :limit => C[:num_items_per_page], :order => 'id DESC')
          render :template => 'torrents/index.rxml', :layout => false
        else
          render_error("Not logged in")
        end
      end
    end
  end

  def search
    @query = params[:query] unless params[:query].blank?
    conditions = []
    if params[:cat]
      @categories = Category.find(params[:cat])
      conditions << "category_id IN (?)"
    end
    if @query
      conditions << "MATCH(name,filename,description) AGAINST (?)"
    end

    conditions = [conditions.join(" AND "), @categories, @query].compact
    @torrents = Torrent.paginate(:conditions => conditions, :order => 'created_at DESC', :page => params[:page])
  end
    
  
  def download
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
  
  def new
    @page_title = "Upload"
    @categories = Category.find(:all, :order => 'name ASC')
    @torrent = Torrent.new
  end

  def create
    @page_title = "Upload"
    @categories = Category.find(:all, :order => 'name ASC')
    
    the_file = params[:torrent].delete(:the_torrent)
    @torrent = Torrent.new(params[:torrent])
    
    if the_file.nil?
      flash[:notice] = "Please select a torrent file to upload."
      render :action => 'new'
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
    
    File.open(tmp_path, "w") { |f| f.write(contents) }
    
    if File.exists?(tmp_path)
      # Get the MetaInfo, confirm that it's a legit torrent
      begin
        meta_info = RubyTorrent::MetaInfo.from_location(tmp_path)
      rescue RubyTorrent::MetaInfoFormatError => e
        flash[:notice] = "The uploaded file does not appear to be a valid .torrent file."
        render :action => 'new'
        return
      rescue StandardError => e
        flash[:notice] = "There was an error processing your upload: #{$!}.  Please contact the admins if this problem persists."
        render :action => 'new'
        return
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
        render :action => 'new'; return
      else
        @torrent.move!(tmp_path)
        
        @torrent.user = current_user
        @torrent.save!
        flash[:notice] = "Success!  Torrent uploaded."
        redirect_to torrent_url(@torrent)
      end
    end
  end
  
  def show
    @torrent = Torrent.find(:first, :conditions => ["torrents.id = ?", params[:id]], :include => :category) rescue nil
    if @torrent.nil?
      redirect_to :back; return
    end
    @torrent.increment!(:views)
    @comments = Comment.paginate(:conditions => ["torrent_id = ?", @torrent.id], :order => 'id ASC', :page => params[:page])
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
