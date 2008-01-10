require_dependency "user"

module LoginSystem 
  
  protected
  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user)
     true
  end
  
  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  # 
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end
   
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(user)
  # 
  def login_required(the_action = nil)
    if not protect?(action_name)
      return true  
    end
    
    # Return true if they are logged in
    return true if current_user

    # store current location so that we can 
    # come back after the user logged in
    store_location
    
    if !the_action.nil?
      flash[:notice] = "Please signup or <a href=\"/login\">login</a> to #{the_action}."
    end
    # call overwriteable reaction to unauthorized access
    access_denied
    return false 
  end

  def access_denied
    redirect_to :controller=>"/account", :action =>"signup"
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session[:return_to] = @request.request_uri
  end
  
  def location_stored?
    !session[:return_to].nil?
  end
  
  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to_url session[:return_to]
      session[:return_to] = nil
    end
  end

  def redirect_to_stored_location
    redirect_to_url session[:return_to]
  end

end
