class Peer < ActiveRecord::Base
  belongs_to :torrent
  
  before_create :ping
  after_save "ping!"
  
  def ping
    self.last_action_at = Time.now
  end

  def ping!
    self.last_action_at = Time.now
    save!
  end
  
end
