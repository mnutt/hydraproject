class Peer < ActiveRecord::Base
  belongs_to :torrent
  
  before_create :ping
  before_save :ping
  
  def ping
    self.last_action_at = Time.now
  end

end
