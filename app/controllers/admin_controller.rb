class AdminController < ApplicationController
  before_filter :admin_required
  
  def index
    config_file = File.join(RAILS_ROOT, 'config', 'config.yml')
    @explanation =  YAML.load(IO.read(File.join(RAILS_ROOT, 'db', 'config_explanation.yml')))
    @config = YAML.load(IO.read(config_file)).sort
  end
  
  def update_config
    @config = params[:config]
    
    @fname = File.join(RAILS_ROOT, 'config', 'config.yml')
    File.open(@fname, 'w') do |f|
      f.puts @config.to_yaml
    end
    
    flash[:notice] = "Configuration updated (config/config.yml). <br/><br/> Note: your mongrels / app server must be restarted for these changes to take effect."
    redirect_to :action => :index
  end
  
  def categories
    @categories = Category.find(:all, :order => 'name ASC')
    if request.post?
      Category.create!(params[:category])
      flash[:notice] = "Category created."
      redirect_to :back
    end
  end
  
  verify :only => :destroy_category, :method=>:post
  def destroy_category
    Category.find(params[:id]).destroy
    flash[:notice] = "Category destroyed."
    redirect_to :back
  end
  
end