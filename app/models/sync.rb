class Sync
  # Responsible for sync'ing operations with other HydraServers in the federation.yml file
  
  def self.first_sync
    TRUSTED_SITES.each do |site|
      unless site['domain'] && site['passkey'] && site['api_url']
        raise InvalidTrustedSiteFormat, "Site must have keys 'domain', 'passkey' and 'api_url' : #{site.inspect}"
      end
      puts "Testing if we can connect to #{site['domain']}:"
      t = Sync.time(site)
      puts "\t#{t}"
      Sync.sync_users(site, -1)
      Sync.sync_torrents(site, -1)
    end
  end
  
  def self.sync_users(site, since)
    hc = Sync.new_hydra_client(site)
    u = hc.list_users(since)
    puts u.inspect
    if u['users']['user'] && !u['users']['user'].empty?
      u['users']['user'].each do |u|
        puts "parsing: #{u.inspect}"
        user = User.find(:first, :conditions => ["login = ?", u['login']])
        if user.nil?
          # Haven't seen this user yet
          user = User.create!(:login => u['login'], :hashed_password => u['hashed_password'], :salt => u['salt'], :passkey => u['passkey'])
          puts "\tCreated New User: #{user.login} -- #{user.hashed_password} -- #{user.passkey}"
        else
          puts "\tUser already in db: #{u['login']}"
        end
      end
    end
  end
  
  def self.sync_transfer_stats(site, last_sync_id=nil)
    # TODO
  end
  
  def self.sync_torrents(site, since)
    hc = Sync.new_hydra_client(site)
    t = hc.list_torrents(since)
    puts t.inspect
    if t['torrents']['torrent'] && !t['torrents']['torrent'].empty?
      t['torrents']['torrent'].each do |thash|
        puts "Processing: #{thash.inspect}"
        torrent = Torrent.find(:first, :conditions => ["info_hash = ?", thash['info_hash']])
        if torrent.nil?
          torrent = Torrent.create!(:info_hash => thash['info_hash'], :name => thash['name'], :description => thash['description'])
          puts "\tCreated New Torrent: #{torrent.info_hash} -- #{torrent.name}"
          # Now we need to grab the actual .torrent file
          grabbed = Sync.grab_torrent(site, torrent)
          if !grabbed
            puts "Grab failed, destroying: #{torrent.inspect}"
            torrent.destroy
          end
        else
          puts "\tTorrent already in DB: #{torrent.info_hash}"
        end
      end
    end
    
  end
  
  def self.grab_torrent(site, torrent)
    # Saves a remote .torrent file locally
    hc = Sync.new_hydra_client(site)
    puts "Grabbing: #{torrent.info_hash} to #{torrent.torrent_path}"
    result, reason = hc.get_torrent(torrent.info_hash, torrent.torrent_path)
    puts "\tResult: #{result}, #{reason}"
    if result
      torrent.print_meta_info
    end
    return result
  end
  
  def self.time(site)
    hc = Sync.new_hydra_client(site)
    hc.time
  end
  
  def self.new_hydra_client(site)
    HydraClient.new(site['api_url'], site['passkey'])
  end
  
end
