# == Schema Information
# Schema version: 20081025182003
#
# Table name: torrent_files
#
#  id         :integer(4)      not null, primary key
#  torrent_id :integer(4)
#  filename   :text
#  size       :integer(4)
#

class TorrentFile < ActiveRecord::Base
  belongs_to :torrent
end
