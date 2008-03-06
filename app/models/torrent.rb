class Torrent < ActiveRecord::Base
  belongs_to :user  # This is only set for the first few days, so the administrator can police new uploads
  belongs_to :category
  
  has_many :torrent_files, :dependent => :destroy
  has_many :peers, :dependent => :destroy
  
  before_save :ensure_non_negative
  before_destroy :cleanup
  
  serialize :orig_announce_list  # An Array of announce URLs
  has_many :comments, :dependent => :destroy, :include => :user, :order => 'comments.id ASC'
  
  # For the will_paginate plugin.  See: http://plugins.require.errtheblog.com/browser/will_paginate/README
  cattr_reader :per_page
  @@per_page = C[:num_items_per_page]

  # pretty URLs
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end
  
  def connectable_peers
    Peer.find(:all, :conditions => ["torrent_id = ? AND connectable = ? ", self.id, true])
  end
  
  def cleanup
    File.unlink(self.torrent_path) if File.exist?(self.torrent_path)
  end
  
  def meta_info
    #puts "\n\nLooking for torrent in path: #{self.torrent_path}\n\n"
    raise TorrentFileNotFoundError unless File.exist?(self.torrent_path)
    RubyTorrent::MetaInfo.from_location(self.torrent_path)
  end
  
  def print_meta_info
    Torrent.dump_metainfo(self.meta_info)
  end
  
  def ensure_non_negative
    self.seeders = 0 if self.seeders < 0
    self.leechers = 0 if self.leechers < 0
  end
  
  def tkey
    "torrent_#{self.id}"
  end
  
  def peer_started!(peer, remote_ip)
    peer.seeder? ? self.seeders +=1 : self.leechers += 1
    
    peers = CACHE.get(self.tkey)
    if peers.nil?
      CACHE.set(self.tkey, {peer.id => remote_ip})
    else
      if peers.has_key?(peer.id)
        # Maybe they've changed IPs
        if !peers[peer.id] == remote_ip
          # they have, changed IPs
          peers.delete(peer.id)
          peers[peer.id] = remote_ip
          CACHE.set(self.tkey, peers)
        end
      else
        # IF the Peer IP does not already exists in the memcache
        peers[peer.id] = remote_ip
        CACHE.set(self.tkey, peers)
      end
    end
  end

  def peer_stopped!(peer, remote_ip)
    peer.seeder? ? self.seeders -= 1 : self.leechers -= 1
    
    peers = CACHE.get(self.tkey)
    if peers && peers.has_key?(peer.id)
      # The MemCache does indeed have this Peer in its cache
      peers.delete(peer.id)
      if peers.empty?
        CACHE.delete(self.tkey)
      else
        CACHE.set(self.tkey, peers)
      end
    end
    # Destroy the peer (it's no longer active)
    peer.destroy
  end

  def peer_completed!(peer, remote_ip)
    self.seeders += 1
    self.leechers -= 1
    self.times_completed += 1
    
    peers = CACHE.get(self.tkey)
    if peers.nil?
      CACHE.set(self.tkey, {peer.id => remote_ip})
    elsif peers && !peers.has_key?(peer.id)
      # Add the peer
      peers[peer.id] = remote_ip
      CACHE.set(self.tkey, peers)
    end
  end
 
  def num_peers
    self.seeders + self.leechers
  end
  
  def base_dir
    File.join(RAILS_ROOT, 'torrents') # We keep torrent files outside of the web root
  end
  
  def move!(from_path)
    FileUtils.mv(from_path, self.torrent_path)
  end
  
  def torrent_path
    File.join(base_dir, "#{self.id}.torrent")
  end
    
  def set_metainfo!(mi = nil)
    if mi.nil?
      mi = self.meta_info
    end
    
    total_size = 0
    mii = mi.info  # MetaInfoInfo
    if mii.single?
      self.size = total_size = mii.length
      self.torrent_files << TorrentFile.create({:filename => mii.name, :size => mii.length})
      self.numfiles = 1
    else
      # Increment total_size for each file
      mii.files.each do |f|
        total_size += f.length
        if f.path.size == 1
          path = f.path.to_s
        else
          path = f.path.join('\\')
        end
        self.torrent_files << TorrentFile.create({:filename => path, :size => f.length})
      end
      self.numfiles = mii.files.size
    end
    self.info_hash = mii.info_hash
    self.piece_length = mii.piece_length
    self.pieces = mii.pieces.length / 20
    self.size = total_size  # bytes
    self.torrent_comment = mi.comment
    self.orig_announce_url = mi.announce.to_s
    if !mi.announce_list.nil?
      #puts "Announce List class: #{mi.announce_list.class}"
      #puts "Announce List: #{mi.announce_list.inspect}"
      self.orig_announce_list = mi.announce_list
    end
    self.created_by = mi.created_by unless mi.created_by.nil?
    if self.name.nil? || self.name.blank?
      set_name_from_torrent_filename
    end
    
    save!
  end
  
  def set_name_from_torrent_filename
    f = self.filename.dup
    # Underscores => spaces
    f = f.gsub(/_/, ' ')
    # Now strip off ".torrent" from the end
    f = f.gsub(/\.torrent$/, '')
    self.name = f
  end
  
  def self.clear_user_ids
    Torrent.find(:all, :conditions => ["user_id IS NOT NULL AND created_at > ?", 3.days.ago]).each do |t|
      t.user_id = nil
      t.save!
    end
  end
  
  def self.dump_metainfoinfo(mii)
    if mii.single?
        <<EOS
         length: #{mii.length / 1024}kb
       filename: #{mii.name}
EOS
    else
      mii.files.map do |f|
          <<EOS
     - filename: #{File.join(mii.name, f.path)}
         length: #{f.length}
EOS
      end.join + "\n"
    end + <<EOS
      info_hash: #{mii.info_hash}
   piece length: #{mii.piece_length / 1024}kb 
         pieces: #{mii.pieces.length / 20}
EOS
  end

  def self.dump_metainfo(mi)
      <<EOS
  #{Torrent.dump_metainfoinfo(mi.info).chomp}
       announce: #{mi.announce}
  announce-list: #{(mi.announce_list.nil? ? "<not specified>" : mi.announce_list.map { |x| x.join(', ') }.join('; '))}
  creation date: #{mi.creation_date || "<not specified>"}
     created by: #{mi.created_by || "<not specified>"}
        comment: #{mi.comment || "<not specified>"}
EOS
  end
  
end
