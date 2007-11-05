class AdminController < ApplicationController
  before_filter :admin_required
  
  def index
    config_file = File.join(RAILS_ROOT, 'config', 'config.yml')
    @config = YAML.load(IO.read(config_file)).sort
  end
  
  def update_config
    @config = params[:config]
    
    @fname = File.join(RAILS_ROOT, 'config', 'config.yml')
    File.open(@fname, 'w') do |f|
      f.puts @config.to_yaml
    end
    
    flash[:notice] = "Config updated. Note: your mongrels / rails app server must be restarted for these changes to take effect."
    redirect_to :action => :index
  end
  
end