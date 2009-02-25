# == Schema Information
# Schema version: 20081025182003
#
# Table name: categories
#
#  id   :integer(4)      not null, primary key
#  name :string(255)
#

class Category < ActiveRecord::Base
  has_many :torrents
  
  # helper method to remove all categories - do not run this if torrents already belong to live data
  def self.clear
    Category.delete_all
  end
  
  def self.create_defaults
    ['Miscellaneous'].each do |name|
      Category.create_cat(name)
    end
  end
  
  def self.create_cat(name)
    return if Category.find_by_name(name)
    Category.create!(:name => name)
  end

end
