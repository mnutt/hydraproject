require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  
  validates_presence_of       :login,       :on => :create
  validates_presence_of       :password,    :on => :create, :if => Proc.new { |user| user.hashed_password.nil? }

  validates_uniqueness_of     :login,       :on => :create

  validates_length_of         :login,       :within => 3..20, :on => :create
  validates_length_of         :password,    :within => 5..40, :on => :create, :if => Proc.new { |user| user.hashed_password.nil? }
  
  before_create :generate_passkey
  
  HARD_SALT = 'TheHydraProject--123456789@!#%@^^#@'

  attr_accessor :password_confirmation

  def ratio
    return 0 if self.uploaded.zero? || self.downloaded.zero?
    return (self.uploaded.to_f / self.downloaded.to_f)
  end
  
  def ratio_friendly
    r = self.ratio
    return "&#8734;" if r.zero?
    return number_with_precision(r, 2)
  end
  
  def downloaded_friendly
    number_to_human_size(self.downloaded)
  end

  def uploaded_friendly
    number_to_human_size(self.uploaded)
  end
  
  def tracker_url
    "#{BASE_URL}tracker/#{self.passkey}/announce"
  end
  
  def generate_passkey
    return unless self.passkey.nil?
    self.passkey = Digest::SHA1.hexdigest("#{self.login}--#{Time.now}--#{rand(10000)}").slice(0, 10)
  end
  
  def generate_passkey!
    generate_passkey
    save!
  end
  
  def moderator?
    self.is_moderator? || self.is_admin?
  end
  
  def self.admin_user
    User.find_by_login('admin')
  end
  
  def set_password!(pass)
    self.password = pass
    save
  end
  
  def remember_me
    # First check to see if there is an existing auth token that has not yet expired.
    #   That way two computers/browsers can share the same auth token until it expires.
    if !self.remember_token.nil? && (Time.now < self.remember_token_expires)
      # Reset the token expiration
      self.remember_token_expires = 1.week.from_now
      self.save_with_validation(false)
    else
      self.remember_token_expires = 1.week.from_now
      self.remember_token = Digest::SHA1.hexdigest("#{self.login}--#{HARD_SALT}--#{self.remember_token_expires}")  # Just some pseudorandom string
      self.save_with_validation(false)
    end
  end

  def forget_me
    self.remember_token_expires = nil
    self.remember_token = nil
    self.save_with_validation(false)
  end
  
  def friendly_name
    return self.login if self.first_name.nil?
    return self.login if self.first_name.blank?
    return self.first_name
  end              

  # Authenticate a user. 
  #
  # Example:
  #   @user = User.authenticate('bob', 'bobpass')
  #
  def self.authenticate(login, pass)
    user = User.find(:first, :conditions => ["login = ?", login]) rescue nil
    return nil unless user
    return nil unless user.passwords_match?(pass)
    return user
  end  
  
  # Authenticate using the username & passkey
  def self.feed_auth(login, passkey)
    User.find(:first, :conditions => ["login = ? AND passkey = ?", login, passkey])
  end
  
  def passwords_match?(pass)
    self.hashed_password == User.encrypted_password(pass, self.salt)
  end
  
  def has_email?
    return false if self.email.nil? || self.email.blank?
    return true
  end
  
  # Returns the user's raw password, only available when the user is first being created.
  def password
    @password
  end

  # Sets a users password by generating a random salt and encrypting it with
  # the passed password.
  def password=(pass)
    @password = pass
    create_new_salt
    if @password && !@password.empty?
      self.hashed_password = User.encrypted_password(self.password, self.salt)
    else
      self.hashed_password = nil
    end
  end

protected

  # Generates a random salt
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end
  
  # One-way password encryption with random and hard coded salts
  def self.encrypted_password(pass, salt)
    Digest::SHA256.hexdigest(pass + HARD_SALT + salt)
  end
  
end
