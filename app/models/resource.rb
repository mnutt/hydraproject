# == Schema Information
# Schema version: 20081025182003
#
# Table name: resources
#
#  id                :integer(4)      not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer(4)
#  file_updated_at   :datetime
#  created_at        :datetime
#  updated_at        :datetime
#  user_id           :integer(4)
#

require 'make-torrent'

class Resource < ActiveRecord::Base
  has_attached_file :file
  belongs_to :user
  has_one :torrent

  after_save :generate_torrent
  
  def torrent_filename
    self.file_file_name + ".torrent"
  end

  def url
    "http://#{C[:domain_with_port]}#{self.file.url}".split("?").first
  end

  def generate_torrent
    torrent_data = MakeTorrent.new(self.file.path, 
                                   self.user.tracker_url, 
                                   self.url)
    torrent = Torrent.new(:filename => self.torrent_filename,
                          :resource => self)
    torrent.set_metainfo!(torrent_data.torrent)
    torrent.save!
    torrent_data.write(torrent.torrent_path)
  end
end
