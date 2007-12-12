class Peer < ActiveRecord::Base
  belongs_to :torrent
  
  before_create :ping
  before_save :ping
  before_destroy :cleanup

  def ping
    self.last_action_at = Time.now
  end

  def connectable_check!(ip, port)
    begin
      Timeout.timeout(8) do
        TCPSocket.new(ip, port)
      end
      
      # If we got here, the peer *IS* connectable!
      self.connectable = true
      save!
      return true
    rescue StandardError, Timeout::Error, TimeoutError, Exception, Interrupt, SignalException
      # NOT connectable -- do nothing because the default is already false
    end
    return false
  end
  
  def cleanup
    remove_from_memcache
    self.seeder? ? self.torrent.seeders -= 1 : self.torrent.leechers -= 1
    self.torrent.save!
  end
  
  private
  
  def remove_from_memcache
    peers = CACHE.get(self.torrent.tkey)
    return if peers.nil? || peers.empty?
    peers.delete(self.id)
    if peers.empty?
      CACHE.delete(self.torrent.tkey)
    else
      CACHE.set(self.torrent.tkey, peers)
    end
  end
  
end
