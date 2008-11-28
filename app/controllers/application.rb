class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  before_filter :check_for_setup
  def check_for_setup
    redirect_to :controller => 'setup', :action => 'index' if !CONFIG_EXISTS or !DB_CONFIG_EXISTS
  end

  # Pick a unique cookie name to distinguish our session data from others'
#  session :session_key => '_hydra_session_id', :secret => 'hydra project super s3333kr333t session secret'
  
  layout C[:layout]
    
  # See: http://www.robbyonrails.com/articles/2007/07/16/rails-code-audit-tips-filtered-parameter-logging
  filter_parameter_logging :password, :current_password, :password_confirmation
  
  protected
  
  def check_logged_in
    return true if current_user
    
    if C[:invite_only]
      flash[:notice] = "This website is currently invitation only.  You may login below if you already have an account."
      redirect_to login_url
    else
      flash[:notice] = "#{C[:app_name]} is a private tracker.  Please <a href=\"/signup\">Signup</a> or <a href=\"/login\">Login</a> to continue."
      redirect_to signup_url
    end
    return false
  end
  
  def get_remote_ip
    e = request.env
    @remote_ip = e['HTTP_X_FORWARDED_FOR'] || e['HTTP_CLIENT_IP'] || e['REMOTE_ADDR'] || nil
    if @remote_ip.nil?
      render_error("Could not determine remote IP Address."); return false
    end
    return @remote_ip
  end
  
  def render_error(msg)
    render :text => error(msg)
  end
  
  def error(msg)
    {'failure reason' => msg}.to_bencoding
  end
  
  def moderator_logged_in?
    return false if current_user.nil?
    return current_user.moderator?
  end
  helper_method :moderator_logged_in?

  def admin_logged_in?
    return false if current_user.nil?
    return current_user.is_admin?
  end
  helper_method :admin_logged_in?
  
  def current_domain
    RAILS_ENV == 'development' ? 'localhost' : 'hydraproject.org'
  end
  helper_method :current_domain
  
  def auth_required
    unless current_user
      session[:after_login_url] = request.request_uri
      flash[:notice] = "Please signup or #{link_to('login', login_url)} to continue."
      redirect_to signup_url; return false
    end
  end

  def moderator_required
    unless moderator_logged_in?
      flash[:notice] = "Access denied.  Contact admin if you believe this was in error."
      redirect_to index_url; return false
    end
  end

  def admin_required
    unless admin_logged_in?
      flash[:notice] = "Access denied.  Contact admin if you believe this was in error."
      redirect_to index_url; return false
    end
  end
  
  def secure?
    false
  end

private

end
