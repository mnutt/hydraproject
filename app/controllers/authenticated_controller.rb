class AuthenticatedController < ApplicationController
  
  protected
  
  # All controllers that inherit from AuthenticatedController should be locked down
  def secure?
    true
  end
  
end
