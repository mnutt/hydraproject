class Mailer < ActionMailer::Base
  
  def welcome(user, password)
    @from                         = "#{C[:app_name]} <#{C[:notifiction_email]}>"
    @recipients                   = user.email
    @subject                      = "Welcome to #{C[:app_name]}"
    @sent_on                      = Time.now
    @body['user']                 = user
    @body['password']             = password
  end

  def notice(subject, body = '')
    @from                         = "<#{C[:notifiction_email]}>"
    @recipients                   = C[:webmaster_email]
    @subject                      = "#{C[:app_name]} Notice: #{subject}"
    @sent_on                      = sent_on
    @body['text']                 = body
  end
  
end
