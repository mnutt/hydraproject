class Sync
  # Responsible for sync'ing operations with other HydraServers in the federation.yml file
  
  def self.first_sync
    TRUSTED_SITES.each do |site|
      unless site['domain'] && site['passkey'] && site['api_url']
        raise InvalidTrustedSiteFormat, "Site must have keys 'domain', 'passkey' and 'api_url' : #{site.inspect}"
      end
      Sync.sync_users(site, -1)
    end
  end
  
  def self.sync_users(site, since)
    hc = Sync.new_hydra_client(site)
    u = hc.list_users(since)
    puts u.inspect
    if (b = User.find_by_login('brianna'))
      b.destroy
    end
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
  
  def self.new_hydra_client(site)
    HydraClient.new(site['api_url'], site['passkey'])
  end
  
end
