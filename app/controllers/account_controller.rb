class AccountController < ApplicationController

  def index
  end
  
  def login
    if request.post?
      if (user = User.authenticate(params[:user_login], params[:user_password]))
        set_current_user(user)
        current_user.remember_me
        set_auth_cookie(current_user)

        flash[:notice] = "Login successful."
        if location_stored?
          redirect_to_stored_location and return
        else
          redirect_to '/' and return
        end
      else
        flash[:notice] = "Login unsuccessful."
        @login = params[:user_login]
      end
    end
  end
  
  def signup
    if C[:invite_only]
      flash[:notice] = "This website is currently invitation only.  You may login below if you already have an account."
      redirect_to :controller => :account, :action => :login; return
    end
    @user = User.new(params[:user])
    
    if request.post?
      
      @user.password                = params[:user][:password]
      @user.password_confirmation   = params[:user][:password_confirmation]
      
      if @user.login.nil? || @user.login.blank?
        flash[:notice] = "Please enter a username."
        return false
      end
    end
    if request.post? and @user.save
      set_current_user(User.authenticate(@user.login, params[:user][:password]))
      
      ## SET THE AUTH TOKEN & COOKIE
      current_user.remember_me
      set_auth_cookie(@user.reload)
      
      email = params[:user][:email]
      if email && !email.blank?
        begin
          Mailer.deliver_welcome(current_user, params[:user][:password])
        rescue Exception => e
        end
      end

      flash[:notice] = "Welcome, #{current_user.login}."

      # If this is the first account created, make the user a sysop
      if 1 == @user.id
        @user.is_admin = true
        @user.is_moderator = true
        @user.save
        flash[:notice] = "Welcome to your new installation of The Hydra Project, rails edition.  You have automatically been made an admin/sysop of this server."
      end
      
      if location_stored?
        redirect_to_stored_location and return
      else
        redirect_to '/' and return
      end
      
      redirect_back_or_default '/' and return
    end      
  end  
  
  def update
    if current_user.update_attributes(params[:user])
      flash[:notice] = 'Profile updated.'
    else
      flash[:notice] = 'Could not update profile.'
    end
    redirect_back_or_default :action => "edit"
  end
  
  def new_password
    passwords = params[:password]
    if current_user && passwords
      if passwords[:new_password] == passwords[:new_password_confirmation]
        current_user.password = User.sha1(passwords[:new_password])
        if current_user.save
          flash[:notice]  = "Success!  Password updated."
          flash[:success] = true
          @_current_user = User.authenticate(current_user.login, passwords[:new_password])
        else
          flash[:notice]  = "Could not update your password. Please try a longer one."
        end
      else
        flash[:notice]  = "Passwords must match, silly."
      end
    else
      flash[:notice]  = "Houston, we have a problem."
    end
    redirect_back_or_default :action => "reset_confirm"
  end
  
  def update_password
    if request.post?
      passwords = params[:password]
      if User.authenticate(current_user.login, passwords[:user_password])
        if passwords[:new_password] == passwords[:new_password_confirmation]
          current_user.set_password!(passwords[:new_password])
          flash[:notice]  = "Success!  Password updated."
        else
          flash[:notice] = "New password(s) entered did not match."
        end
      else
        flash[:notice] = "Password could not be changed.  Perhaps you mistyped your old password?"
      end
    end
    redirect_back_or_default :action => "change_password"
  end
  
  def logout
    if current_user
      current_user.forget_me
      @_current_user = nil
    end
    unset_auth_cookie
  end

  def edit
    @user = current_user
  end

  def change_password
  end
  
protected
    
  def secure?
    ["index", "update", "welcome", "edit", "change_password"].include?(action_name)
  end

private
  
  def setup_user
    if params[:login] && !params[:login].blank?
      @user = User.find_by_login(params[:login]) rescue nil
    end
    if !@user
      flash[:notice] = "Could not find user #{params[:login]}."
      redirect_to :back and return
    end
  end

end
