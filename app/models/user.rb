# == Schema Information
# Schema version: 20081025182003
#
# Table name: users
#
#  id                        :integer(4)      not null, primary key
#  login                     :string(40)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  is_admin                  :boolean(1)
#  is_moderator              :boolean(1)
#  remember_token            :string(40)
#  remember_token_expires_at :datetime
#  created_at                :datetime
#  updated_at                :datetime
#  passkey                   :string(255)
#  uploaded                  :integer(4)      default(0)
#  downloaded                :integer(4)      default(0)
#  downloaded_local          :integer(4)      default(0)
#  uploaded_local            :integer(4)      default(0)
#  is_local                  :boolean(1)      default(TRUE)
#  name                      :string(100)     default("")
#  email                     :string(100)
#  activation_code           :string(40)
#  activated_at              :datetime
#

require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email, :if => Proc.new { C[:require_email] }
  validates_length_of       :email,    :within => 6..100, :allow_nil => true
  validates_uniqueness_of   :email, :if => Proc.new { C[:require_email] }
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message, :if => Proc.new { C[:require_email] }
  validate                  :verify_age

  before_create :make_activation_code 
  before_create :generate_passkey

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :age_verify
  attr_accessor :age_verify

  # Activates the user in the database.
  def activate!
    @activated = true
    self.activated_at = Time.now.utc
    self.activation_code = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def active?
    # the existence of an activation code means they have not activated yet
    activation_code.nil? or !C[:require_email]
  end

  def verify_age
    errors.add(:age_verify, "You must be at least 13 years old to sign up.") if self.new_record? && self.age_verify != "1"
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    if C[:require_email]
      u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login] # need to get the salt
    else
      u = find :first, :conditions => {:login => login}
    end
    u && u.authenticated?(password) ? u : nil
  end

  # Authenticate using the username & passkey
  def self.feed_auth(login, passkey)
    User.find(:first, :conditions => ["login = ? AND passkey = ?", login, passkey])
  end

  def self.admin_user
    User.find_by_login('admin')
  end

  def friendly_name
    return self.login if self.first_name.nil?
    return self.login if self.first_name.blank?
    return self.first_name
  end  

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def has_email?
    !(self.email.nil? || self.email.blank?)
  end

  def moderator?
    self.is_moderator? || self.is_admin?
  end

  # Bittorrent stuff
  def ratio
    return 0 if self.uploaded.zero? || self.downloaded.zero?
    return (self.uploaded.to_f / self.downloaded.to_f)
  end
  
  def ratio_friendly
    r = self.ratio
    return "&#8734;" if r.zero?
    return number_with_precision(r, 2)
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

  protected
    
    def make_activation_code
        self.activation_code = self.class.make_token
    end


end
