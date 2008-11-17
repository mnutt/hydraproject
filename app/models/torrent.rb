# == Schema Information
# Schema version: 20081025182003
#
# Table name: torrents
#
#  id                 :integer(4)      not null, primary key
#  info_hash          :string(255)
#  name               :string(255)
#  user_id            :integer(4)
#  filename           :string(255)
#  description        :text
#  category_id        :integer(4)
#  size               :integer(4)
#  piece_length       :integer(4)
#  pieces             :integer(4)
#  orig_announce_url  :string(255)
#  orig_announce_list :text
#  created_by         :string(255)
#  torrent_comment    :string(255)
#  numfiles           :integer(4)
#  views              :integer(4)      default(0)
#  times_completed    :integer(4)      default(0)
#  leechers           :integer(4)      default(0)
#  seeders            :integer(4)      default(0)
#  created_at         :datetime
#  updated_at         :datetime
#  resource_id        :integer(4)
#  url_list           :string(255)
#

class Torrent < ActiveRecord::Base
  belongs_to :user  # This is only set for the first few days, so the administrator can police new uploads
  belongs_to :category
  belongs_to :resource
  
  has_many :torrent_files, :dependent => :destroy
  has_many :peers, :dependent => :destroy
  has_many :comments, :dependent => :destroy, :include => :user, :order => 'comments.id ASC'
  
  before_save :ensure_non_negative
  before_destroy :cleanup
  
  serialize :orig_announce_list  # An Array of announce URLs
  
  # For the will_paginate plugin.  See: http://plugins.require.errtheblog.com/browser/will_paginate/README
  cattr_reader :per_page
  @@per_page = C[:num_items_per_page]
  attr_accessor :the_torrent

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

  def add_peer_to_cache(peer, remote_ip)
    peers = CACHE.get(self.tkey) || {}
    original_peers = peers.clone
    peers.merge!(peer.id => remote_ip) 
    CACHE.set(self.tkey, peers) unless peers == original_peers # don't do unnecessary cache set
  end
  
  def peer_started!(peer, remote_ip)
    peer.seeder? ? self.seeders +=1 : self.leechers += 1
    
    add_peer_to_cache(peer, remote_ip)
  end

  def peer_completed!(peer, remote_ip)
    self.seeders += 1
    self.leechers -= 1
    self.times_completed += 1
    
    add_peer_to_cache(peer_remote_ip)
  end

  def peer_stopped!(peer, remote_ip)
    peer.seeder? ? self.seeders -= 1 : self.leechers -= 1
    
    peers = CACHE.get(self.tkey)
    
    if peers.delete(peer.id)
      if peers.empty?
        CACHE.delete(self.tkey)
      else
        CACHE.set(self.tkey, peers)
      end
    end

    # Destroy the peer (it's no longer active)
    peer.destroy
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

    mii = mi.info # MetaInfoInfo

    create_torrent_files(mii)

    self.numfiles           = mii.single? ? 1 : mii.files.size
    self.size               = get_mii_file_size(mii) 
    self.info_hash          = mii.info_hash
    self.piece_length       = mii.piece_length
    self.pieces             = mii.pieces.length / 20
    self.torrent_comment    = mi.comment
    self.url_list           = mi.url_list
    self.orig_announce_url  = mi.announce.to_s
    self.created_by         = mi.created_by              unless mi.created_by.nil?
    self.orig_announce_list = mi.announce_list           unless mi.announce_list.nil?
    self.name               = name_from_torrent_filename if self.name.blank?
    
    save!
  end

  def get_mii_file_size(mii)
    if mii.single? 
      mii.length 
    else
      mii.files.inject(0) { |s, f| s + f.length } # sum of all file lengths, in bytes
    end
  end

  def create_torrent_files(mii)
    if mii.single?
      self.torrent_files.create({:filename => mii.name, :size => mii.length})
    else
      mii.files.each do |f|
        path = [f.path].flatten.join('\\')
        self.torrent_files.create({:filename => path, :size => f.length})
      end
    end
  end
  
  def name_from_torrent_filename
    f = self.filename.dup
    # Underscores => spaces
    f.gsub!(/_/, ' ')
    # Now strip off ".torrent" from the end
    f.gsub!(/\.torrent$/, '')
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
       url-list: #{mi.url_list || "<not specified>"}
EOS
  end
  
end
