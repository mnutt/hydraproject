class Sync
  # Responsible for sync'ing operations with other HydraServers in the federation.yml file
  
  def self.first_sync
    TRUSTED_SITES.each do |site|
      unless site[:domain] && site[:passkey] && site[:api_url]
        raise InvalidTrustedSiteFormat, "Site must have keys 'domain', 'passkey' and 'api_url' : #{site.inspect}"
      end
      puts "Testing if we can connect to #{site[:domain]}:"
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
    
    if !u.has_key?('users')
      puts "Result is missing key: 'users'"
      return
    end
    user_list = u['users']
    if user_list.nil? || user_list.empty?
      puts "No users to add.  User list was empty."
      return
    end
    puts "user_list = #{user_list.inspect}"
    u['users'].each do |uhash|
      puts "uhash = #{uhash.inspect}"
      next unless uhash.is_a?(Array) && uhash.first == 'user'
      burn, uhash = *uhash
      
      puts "NOW uhash = #{uhash.inspect}"
      unless uhash.has_key?('salt') && uhash.has_key?('hashed_password') && uhash.has_key?('login') && uhash.has_key?('passkey')
        raise ApiResponseMissingExpectedKeys, "User response hash missing a key or keys.  Keys present: #{uhash.keys}"
      end
      
      salt, hashed_password, passkey, login = uhash['salt'], uhash['hashed_password'], uhash['passkey'], uhash['login']
      
      puts "salt, hashed_password, passkey, login = #{salt}, #{hashed_password}, #{passkey}, #{login}"
      
      user = User.find(:first, :conditions => ["login = ?", login])
      if user.nil?
        # Haven't seen this user yet
        user = User.create!(:login =>login, :hashed_password => hashed_password, :salt => salt, :passkey => passkey)
        puts "\tCreated New User: #{user.login} -- #{user.hashed_password} -- #{user.passkey} -- #{user.salt}"
      else
        puts "\tUser already in db: #{login}"
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
          torrent = Torrent.create!(:info_hash => thash['info_hash'], :name => thash['name'].unescape_xml,
                                    :filename => thash['filename'].unescape_xml, :description => thash['description'].unescape_xml)
          puts "\tCreated New Torrent: #{torrent.info_hash} -- #{torrent.name}"
          # Now we need to grab the actual .torrent file
          grabbed = Sync.grab_torrent(site, torrent)
          if !grabbed
            puts "Grab failed, destroying: #{torrent.inspect}"
            torrent.destroy
          end
          if thash['category'] && !thash['category'].blank?
            # Now find the category
            cat = Category.find(:first, :conditions => ["name = ?", thash['category']])
            if cat
              torrent.category_id = cat.id
              torrent.save!
            elsif C[:auto_add_categories]
              # If the config setting has enabled auto-adding of categories, add it automatically here:
              cat = Category.create!(:name => thash['category'])
              torrent.category_id = cat.id
              torrent.save!
            end
          end
          
          begin
            # IMPORTANT: Set the meta info (things like filesize, list of files, etc)
            torrent.set_metainfo!
            
          rescue RubyTorrent::MetaInfoFormatError => e
            subject, msg = 'Sync Received Invalid .torrent', "From site: #{site.inspect}\n\nThe error: #{e.to_s}\n\nTorrent Hash: #{thash.inspect}"
            Mailer.deliver_notice(subject, msg)
            puts "\n\n\n !!!!!!! \n\n #{subject}\n\n#{msg}\n\n"
            sleep 5
          rescue StandardError => e
            subject, msg = 'Sync Rescued an Error While Grabbing a .torrent', "From site: #{site.inspect}\n\nThe error: #{e.to_s}\n\nTorrent Hash: #{thash.inspect}"
            Mailer.deliver_notice(subject, msg)
            puts "\n\n\n !!!!!!! \n\n #{subject}\n\n#{msg}\n\n"
            sleep 5
          end
          
        else
          puts "\tTorrent already in DB: #{thash['info_hash']}"
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
    HydraClient.new(site[:api_url], site[:passkey])
  end
  
end
