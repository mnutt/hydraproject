class TorrentsController < ApplicationController
  include ApplicationHelper
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
    @bencoded = @torrent.data_with_passkey(current_user.passkey)
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
    @torrent = Torrent.find(params[:id]) rescue nil
    if @torrent.nil?
      redirect_to :back; return
    end
    @torrent.increment!(:views)
    @comments = Comment.paginate(:conditions => ["torrent_id = ?", @torrent.id], :order => 'id ASC', :page => params[:page])
  end
  
  def destroy #AJAX & ADMIN only
    moderator_required
    @torrent = Torrent.find(params[:id])
    if @torrent.destroy
      flash[:notice] = "Torrent removed."
    else
      raise "There was a problem removing the torrent"
      flash[:notice] = "There was a problem removing the torrent"
    end

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
