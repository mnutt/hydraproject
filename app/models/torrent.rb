class Torrent < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
  
  has_many :torrent_files
  
  serialize :orig_announce_list  # An Array of announce URLs
  
  def torrent_url
    "/torrents/#{self.filename}"
  end
  
  def num_peers
    self.seeders + self.leechers
  end
  
  def base_dir
    File.join(RAILS_ROOT, 'public', 'torrents')
  end
  
  def move!(from_path)
    self.filename = get_ok_filename()
    FileUtils.mv(from_path, File.join(base_dir, self.filename))
  end
  
  def torrent_path
    File.join(base_dir, self.filename)
  end
  
  def get_ok_filename
    dir = base_dir
    default_path = File.join(dir, self.original_filename)
    return self.original_filename if !File.exist?(default_path)
    
    without_ext = self.original_filename.gsub(/\.torrent$/, '')
    1.upto(20) do |i|
      new_fname = "#{without_ext}_#{i}.torrent"
      new_path = File.join(dir, new_fname)
      return new_fname if !File.exist?(new_path)
    end
    return rand_ok_fname(without_ext)
  end
  
  # Always make sure we have a unique .torrent filename
  def rand_ok_fname(without_ext)
    path = File.join(base_dir, "#{without_ext}_#{rand(10000)}.torrent")
    if !File.exist?(path)
      return path
    else
      return rand_ok_fname(without_ext)
    end
  end
  
  def set_metainfo!(mi)
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
      puts "Announce List class: #{mi.announce_list.class}"
      puts "Announce List: #{mi.announce_list.inspect}"
      self.orig_announce_list = mi.anounce_list
    end
    self.created_by = mi.created_by unless mi.created_by.nil?
    if self.name.nil? || self.name.blank?
      set_name_from_torrent_filename
    end
    
    save!
  end
  
  def set_name_from_torrent_filename
    f = self.original_filename.dup
    # Underscores => spaces
    f = f.gsub(/_/, ' ')
    # Now strip off ".torrent" from the end
    f = f.gsub(/\.torrent$/, '')
    self.name = f
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
