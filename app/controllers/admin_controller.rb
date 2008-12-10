class AdminController < ApplicationController
  before_filter :admin_required
  
  def index
    config_file = File.join(RAILS_ROOT, 'config', 'config.yml')
    @explanation =  YAML.load(IO.read(File.join(RAILS_ROOT, 'db', 'config_explanation.yml')))
    @config = YAML.load(IO.read(config_file))
    @config.delete('permissions')
    @config = @config.sort
  end
  
  def update_config
    # Massage config into the form we want to save it in
    @config = params[:config].to_hash
    @config['permissions'] = @config['permissions'].to_hash
    @config['permissions'].each do |role, values|
      @config['permissions'][role] = values.map{|value| value.to_sym}
    end
    @config['permissions']['admin'] = [:view, :download, :upload, :web_seed]
    @config['permissions'].symbolize_keys!
    
    @fname = File.join(RAILS_ROOT, 'config', 'config.yml')
    File.open(@fname, 'w') do |f|
      f.write YAML::dump(@config)
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
