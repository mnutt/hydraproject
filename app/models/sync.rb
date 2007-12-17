class Sync
  # Responsible for sync'ing operations with other HydraServers in the federation.yml file
  
  def self.first_sync
    TRUSTED_SITES.each do |site|
      puts "Testing if we can connect to #{site[:domain]}:"
      t = Sync.time(site)
      puts "\t#{t}"
      Sync.sync_users(site, -1)
      Sync.sync_torrents(site, -1)
    end
  end
  
  def self.sync_every_five(since = 10.minutes)
    # We set the default to 10 minutes to ensure no torrents are missed due to overlap
    TRUSTED_SITES.each do |site|
#      begin
        puts "Testing if we can connect to #{site[:domain]}:"
        t = Sync.time(site)
        puts "\tRemote Time: #{t.inspect}"
        Sync.sync_users(site, since)
        Sync.sync_torrents(site, since)
#      rescue StandardError => e
#         Mailer.deliver_notice("[#{C[:domain]}] Error in Sync.sync_every_five", "Site: #{site.inspect}\nError: #{e.to_s}")
#      end
    end
  end
  
  # Sync Transfer Stats daily since there's more overhead
  def self.sync_daily
    TRUSTED_SITES.each do |site|
      begin
        puts "Testing if we can connect to #{site[:domain]}:"
        t = Sync.time(site)
        puts "Site: #{site.inspect}\n\t#{t.inspect}"
        Sync.sync_transfer_stats(site)
      rescue StandardError => e
         Mailer.deliver_notice("[#{C[:domain]}] Error in Sync.sync_daily", "Site: #{site.inspect}\nError: #{e.to_s}")
      end
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

    #puts "\n\n user_list Class: #{user_list.class}\n\n"
    #puts "user_list: #{user_list.inspect}\n\n"
    #sleep 5
    
    users = user_list['user']
    
    users.each do |uhash|
      #puts "\n\n uhash Class: #{uhash.class}\n\n"
      #puts "uhash: #{uhash.inspect}\n\n"
      #sleep 5

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
  
  # Usage:
  #  Sync.sync_transfer_stats(site, nil, true) -- forces the first load
  #  Sync.sync_transfer_stats(site) -- will attempt to find the previous Sync ID for this site and perform the next sync
  #
  def self.sync_transfer_stats(site, last_sync_id=nil, force_first = false)
    if last_sync_id.nil? && !force_first
      # Find the previous Sync (if it exists) and use that
      rs = RatioSync.last(site[:domain])
      last_sync_id = (rs.nil?) ? nil : rs.sync_id
    end
    
    hc = Sync.new_hydra_client(site)
    stats = hc.list_transfer_stats(last_sync_id)
    puts stats.inspect
    if !stats.is_a?(Hash)
      raise SyncXmlToHashError, "XML to Hash in Sync.sync_transfer_stats di not get back hash"
    end
    
    if !stats.has_key?('response')
      raise ApiResponseMissingExpectedKeys, "Missing key in Sync.sync_transfer_stats: 'response'"
    end
    response = stats['response']
    if !response.has_key?('sync_id') || !response.has_key?('users')
      raise ApiResponseMissingExpectedKeys, "Missing key in Sync.sync_transfer_stats (response Hash): 'users' or 'sync_id'"
    end
    sync_id = response['sync_id']
    users = response['users']
    stats = users['user']
    if stats.empty?
      return
    end
    ratio_sync = RatioSync.create!(:domain => site[:domain], :sync_id => sync_id)
    stats.each do |stat|
      puts "user stat: #{stat.inspect}"
      user = User.find(:first, :conditions => ["login = ?", stat['login']])
      rs = RatioSnapshot.create!(:ratio_sync_id => ratio_sync.sync_id, :user_id => user.id, :login => user.login,
                                 :downloaded => stat['downloaded'], :uploaded => stat['uploaded'])
      
      puts "\tCreated new Ratio Snapshot: #{rs.ratio_sync_id} :: #{rs.user_id} :: #{rs.login} :: UL, DL: #{rs.downloaded} :: #{rs.uploaded}"
      # Now increase the actual users D/L and U/L totals if there is new
      if (rs.downloaded > 0) || (rs.uploaded > 0)
        user.downloaded += rs.downloaded
        user.uploaded += rs.uploaded
        user.save!
      end
    end
  end
  
  def self.sync_torrents(site, since)
    hc = Sync.new_hydra_client(site)
    t = hc.list_torrents(since)
    puts t.inspect
    return if t['torrents'].nil?
    if t['torrents']['torrent'] && !t['torrents']['torrent'].empty?
      t['torrents']['torrent'].each do |thash|
        puts "Processing: #{thash.inspect}"
        torrent = Torrent.find(:first, :conditions => ["info_hash = ?", thash['info_hash']])
        if torrent.nil?
          torrent = Torrent.create!(:info_hash => thash['info_hash'], :name => (thash['name'] || '(Untitled)').unescape_xml,
                                    :filename => (thash['filename'] || '').unescape_xml, :description => (thash['description'] || '').unescape_xml)
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
