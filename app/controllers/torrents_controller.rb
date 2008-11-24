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
    
    @torrent = Torrent.new(params[:torrent])
    @torrent.user = current_user
    if @torrent.save
      redirect_to torrents_url
    else
      flash[:notice] = "Failed to save torrent"
      render :action => "new"
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
