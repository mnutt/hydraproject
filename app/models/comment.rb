# == Schema Information
# Schema version: 20081025182003
#
# Table name: comments
#
#  id         :integer(4)      not null, primary key
#  comment    :text
#  torrent_id :integer(4)
#  user_id    :integer(4)
#  created_at :datetime
#

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :torrent

  attr_accessible :comment, :torrent_id
  
  cattr_reader :per_page
  @@per_page = C[:num_items_per_page]
  
end
