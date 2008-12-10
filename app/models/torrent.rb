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
  
  before_create :get_meta_from_file
  before_save :ensure_non_negative
  after_create :move!
  after_create :create_torrent_files
  before_destroy :cleanup

  validates_uniqueness_of :info_hash
  
  serialize :orig_announce_list  # An Array of announce URLs
  
  # For the will_paginate plugin.  See: http://plugins.require.errtheblog.com/browser/will_paginate/README
  cattr_reader :per_page
  @@per_page = C[:num_items_per_page]
  attr_accessor :the_file, :tmp_path

  # pretty URLs
  def to_param
    "#{id}-#{name.downcase.gsub(/[^[:alnum:]]/,'-')}".gsub(/-{2,}/,'-')
  end
  
  def cleanup
    File.unlink(self.torrent_path) if File.exist?(self.torrent_path)
  end
  
  def meta_info
    raise TorrentFileNotFoundError unless File.exist?(self.torrent_path)
    @meta_info_cache ||= RubyTorrent::MetaInfo.from_location(self.torrent_path)
  end
  
  def print_meta_info
    Torrent.dump_metainfo(self.meta_info)
  end

  def data_with_passkey(passkey=nil)
    mi = meta_info
    mi.key = passkey || ""
    announce_url = passkey ? "#{BASE_URL}tracker/#{passkey}/announce" : "#{BASE_URL}tracker/announce"
    mi.announce = URI.parse(announce_url)
    
    # Here's where the announce-list magic happens
    # Set not only this announce URL, but announce URLs for all trackers in the federation
    announce_urls = [mi.announce]

    # Only add trusted sites if the user is logged in
    if passkey
      TRUSTED_SITES.each do |site|
        announce_url = site[:announce_url].gsub('{{passkey}}', passkey)
        # IMPORTANT - each 'announce_url' must be enclosed in an Array.
        #    See: http://wiki.depthstrike.com/index.php/P2P:Protocol:Specifications:Multitracker
        #    And: http://bittornado.com/docs/multitracker-spec.txt
        #
        # When there are multiple announce_urls in the first tier (i.e. all in a single array), then clients will simply
        #   shuffle that array and connect to the first random announce_url.
        #
        # Instead, what we want is for the torrent client to connect to *ALL* of the trackers.
        #
        announce_urls << URI.parse(announce_url)
      end
    end

    mi.announce_list = announce_urls.collect { |url| [url] }
    mi.to_bencoding
  end

  def get_meta_from_file
    if self.the_file.nil?
      self.errors.add_to_base("Please select a torrent file to upload.")
      return false
    end

    contents = self.the_file.is_a?(String) ? the_file : the_file.read
    
    File.open(tmp_path, "w") { |f| f.write(contents) }
    
    if !File.exists?(tmp_path)
      self.errors.add_to_base("There was a problem writing the file to the server.")
      return false
    end

    # Get the MetaInfo, confirm that it's a legit torrent
    begin
      meta_info = RubyTorrent::MetaInfo.from_location(tmp_path)
    rescue RubyTorrent::MetaInfoFormatError => e
      self.errors.add_to_base "The uploaded file does not appear to be a valid .torrent file."
      return false
    rescue StandardError => e
      self.errors.add_to_base "There was an error processing your upload: #{$!}.  Please contact the admins if this problem persists."
      return false
    end
    
    self.filename = original_filename
   
    logger.warn Torrent.dump_metainfo(meta_info)

    self.set_metainfo(meta_info)
  end

  def original_filename
    is_safari = self.the_file.is_a?(String)
    safari_filename = self.name.blank? ? 'unknown.torrent' : "#{self.name.guidify}.torrent"
    is_safari ? safari_filename : the_file.original_filename
  end

  def tmp_path
    return @tmp_path if @tmp_path
    begin
      path = File.join(RAILS_ROOT, 'tmp', 'uploads', "#{self.user.id}_#{rand(1000)}_#{original_filename}")
    end while File.exist?(path)
    @tmp_path = path
  end
  
  def ensure_non_negative
    self.seeders = 0 if self.seeders < 0
    self.leechers = 0 if self.leechers < 0
  end
  
  def tkey
    "torrent_#{self.id}"
  end

  def add_peer_to_cache(peer, remote_ip)
    peers = (Rails.cache.read(self.tkey) || {}).dup
    original_peers = peers.clone
    peers.merge!(peer.id => remote_ip) 
    Rails.cache.write(self.tkey, peers) unless peers == original_peers # don't do unnecessary cache set
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
    
    peers = (Rails.cache.read(self.tkey) || {}).dup
    
    if peers.delete(peer.id)
      if peers.empty?
        Rails.cache.delete(self.tkey)
      else
        Rails.cache.write(self.tkey, peers)
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
  
  def move!
    FileUtils.mv(tmp_path, self.torrent_path)
  end
  
  def torrent_path
    File.join(base_dir, "#{self.id}.torrent")
  end
    
  def set_metainfo(mi = nil)
    if mi.nil?
      mi = self.meta_info
    end

    mii = mi.info # MetaInfoInfo

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
    mi
  end

  def get_mii_file_size(mii)
    if mii.single? 
      mii.length 
    else
      mii.files.inject(0) { |s, f| s + f.length } # sum of all file lengths, in bytes
    end
  end

  def create_torrent_files
    mi = RubyTorrent::MetaInfo.from_location(torrent_path)
    mii = mi.info
    if mii.single?
      @torrent_file = self.find_or_new_torrent_file(mii.name, mii.length)
      @torrent_file.save
    else
      mii.files.each do |f|
        path = [f.path].flatten.join('\\')
        @torrent_file = self.find_or_new_torrent_file(path, f.length)
        @torrent_file.save
      end
    end
  end

  def find_or_new_torrent_file(filename, size)
    torrent_file = self.torrent_files.find_or_create_by_filename(filename)
    torrent_file.size = size
    torrent_file
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
