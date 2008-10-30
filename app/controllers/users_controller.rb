class UsersController < ApplicationController
  # render new.html.erb
  def new
    @user = User.new
  end
 
  def create
    if C[:invite_only]
      flash[:notice] = "This website is currently invitation only.  You may login below if you already have an account."
      redirect_to login_url
      return
    end

    logout_keeping_session!
    @user = User.new(params[:user])
    success = @user && @user.save
    if success && @user.errors.empty?
      # If this is the first account created, make the user a sysop
      if 1 == @user.id
        @user.is_admin = true
        @user.is_moderator = true
        @user.save
        flash[:notice] = "Welcome to your new installation of The Hydra Project, rails edition.  You have automatically been made an admin/sysop of this server."
      else
        flash[:notice] = "Welcome, #{@user.login}."
      end
      redirect_back_or_default('/')
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
end
