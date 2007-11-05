class Peer < ActiveRecord::Base
  belongs_to :torrent
  
  before_create :ping
  before_save :ping
  before_destroy :remove_from_memcache
  
  def ping
    self.last_action_at = Time.now
  end
  
  def remove_from_memcache
    peers = CACHE.get(@torrent.tkey)
    
    return if peers.nil? || peers.empty?
    
    peers.delete(self.id)
    
    if peers.empty?
      CACHE.delete(self.torrent.tkey)
    else
      CACHE.set(self.torrent.tkey, peers)
    end
    
  end
  
end
