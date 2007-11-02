class Category < ActiveRecord::Base
  has_many :torrents
end
