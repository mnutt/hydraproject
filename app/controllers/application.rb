require_dependency 'login_system'

class ApplicationController < ActionController::Base
  include LoginSystem
  
  # Pick a unique cookie name to distinguish our session data from others'
#  session :session_key => '_hydra_session_id', :secret => 'hydra project super s3333kr333t session secret'
  
  layout C[:layout]
  
  before_filter :login_from_cookie
  before_filter :authenticate
  
  # See: http://www.robbyonrails.com/articles/2007/07/16/rails-code-audit-tips-filtered-parameter-logging
  filter_parameter_logging :password, :current_password, :password_confirmation
  
  protected
  
  def check_logged_in
    return true if user_logged_in?
    
    if C[:invite_only]
      flash[:notice] = "This website is currently invitation only.  You may login below if you already have an account."
      redirect_to :controller => :account, :action => :login
    else
      flash[:notice] = "#{C[:app_name]} is a private tracker.  Please <a href=\"/account/signup\">Signup</a> or <a href=\"/account/login\">Login</a> to continue."
      redirect_to :controller => :account, :action => :signup
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
  
  def current_user
    @_current_user
  end
  helper_method :current_user
  
  def set_current_user(user)
    @_current_user = user
  end
  helper_method :set_current_user
  
  def reload_user
    @_current_user.reload
  end

  def user_logged_in?
    !@_current_user.nil?
  end
  helper_method :user_logged_in?
  
  def moderator_logged_in?
    return false if !user_logged_in?
    return current_user.moderator?
  end
  helper_method :moderator_logged_in?

  def admin_logged_in?
    return false if !user_logged_in?
    return current_user.is_admin?
  end
  helper_method :admin_logged_in?
  
  # Login via Cookie
  #
  # Each member gets an auth_token and token expiration date whenever they login.
  #
  def login_from_cookie
    auth_token = cookies[:auth_token]

    return unless !auth_token.blank?

    user = User.find_by_remember_token(auth_token)

    if user && user.remember_token_expires && (Time.now < user.remember_token_expires)
      set_current_user(user)
    end
  end
  
  def current_domain
    if RAILS_ENV == 'development'
      'localhost'
    else
      'hydraproject.org'
    end
  end
  helper_method :current_domain
  
  def unset_auth_cookie
    cookies[:auth_token] = { :value => 'nil', :expires => Time.now - 1.year}
  end
  helper_method :unset_auth_cookie
  
  def set_auth_cookie(user)
    cookies[:auth_token] = { :value => user.remember_token, :expires => 1.week.from_now.utc }
    #logger.warn "cookies = #{cookies.inspect}"
  end
  helper_method :set_auth_cookie
  
  def auth_required
    unless user_logged_in?
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

  def authenticate
    if secure? && !user_logged_in?
      session["return_to"] = request.request_uri
      flash[:notice] = "Please login to view this page."
      redirect_to :controller => 'account', :action => 'login'
      return false
    end
  end

end
