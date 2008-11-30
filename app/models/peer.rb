# == Schema Information
# Schema version: 20081025182003
#
# Table name: peers
#
#  id              :integer(4)      not null, primary key
#  torrent_id      :integer(4)
#  peer_id         :string(255)
#  port            :integer(4)
#  passkey         :string(255)
#  uploaded        :integer(4)      default(0)
#  downloaded      :integer(4)      default(0)
#  to_go           :integer(4)      default(0)
#  seeder          :boolean(1)
#  connectable     :boolean(1)
#  user_id         :integer(4)
#  agent           :string(255)
#  finished_at     :datetime
#  download_offset :integer(4)      default(0)
#  upload_offset   :integer(4)      default(0)
#  last_action_at  :datetime
#  created_at      :datetime
#  updated_at      :datetime
#

class Peer < ActiveRecord::Base
  belongs_to :torrent
  
  before_create :ping
  before_save :ping
  before_destroy :cleanup

  named_scope :connectable, :conditions => {:connectable => true}

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
    peers = (Rails.cache.read(self.torrent.tkey) || {}).dup
    return if peers.nil? || peers.empty?
    peers.delete(self.id)
    if peers.empty?
      Rails.cache.delete(self.torrent.tkey)
    else
      Rails.cache.write(self.torrent.tkey, peers)
    end
  end
  
end
