class Cleanup
  # Used for the cron jobs, etc
  
  def self.remove_dead_peers
    # If we haven't heard from a peer within 130% of the announce interval time, kill it
    last_heard_max = (C[:num_announce_interval_minutes] * 1.3).to_i  # In minutes, still
    Peer.destroy_all ["last_action_at < ?", Time.now.ago(last_heard_max.minutes)]
  end
  
  def self.remove_dead_torrents
    # If a torrent is older than torrent TTL, and has no peers, automatically kill it
    Torrent.destroy_all ["seeders=0 AND leechers=0 AND created_at < ", C[:num_torrent_days_to_live].days.ago]
  end
  
end
