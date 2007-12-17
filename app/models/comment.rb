class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :torrent

  attr_accessible :comment, :torrent_id
  
  cattr_reader :per_page
  @@per_page = C[:num_items_per_page]
  
end
