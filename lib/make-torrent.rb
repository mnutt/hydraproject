require 'digest/sha1'
require 'rubytorrent'

class MakeTorrent
  def initialize(file_path, tracker_url, file_url=nil)
    @file_path = file_path
    @file_url = file_url
    @file_size = File.size(@file_path)
    @tracker = tracker_url

    [64, 128, 256, 512].each do |size|
      @num_pieces = (@file_size.to_f / size / 1024.0).ceil
      tsize = @num_pieces.to_f * 20.0 + 100
      @piece_size = size * 1024
      break if tsize < 10240
    end
  end

  def pieces
    mii_pieces = ""
    read_pieces(@file_path, @piece_size) do |piece|
      mii_pieces += Digest::SHA1.digest(piece)
    end
    mii_pieces
  end

  def write(path)
    File.open(path, 'wb') do |f|
      f.write(torrent.to_bencoding)
    end
  end

  def read_pieces(file, length)
    buf = ""
    File.open(file) do |fh|
      begin
        read = fh.read(length - buf.length)
        if (buf.length + read.length) == length
          yield(buf + read)
          buf = ""
        else
          buf += read
        end
      end until fh.eof?
    end

    yield buf
  end

  def file_name
    File.basename(@file_path)
  end

  def info
    @info ||= { 'pieces' => pieces, 
                'piece length' => @piece_size, 
                'name' => file_name, 
                'files' => [{'path' => [file_name], 'length' => @file_size}] }
  end

  def torrent
    return @torrent_data unless @torrent_data.nil?
    
    torrent = RubyTorrent::MetaInfo.new({'announce_list' => [@tracker],
                                         'announce' => @tracker,
                                         'url-list' => @file_url,
                                         'info' => info,
                                         'creation date' => Time.now})
    @torrent_data = torrent
  end                           
end
