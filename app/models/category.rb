class Category < ActiveRecord::Base
  has_many :torrents
  
  def self.all
    Category.find(:all, :order => 'name DESC')
  end
  
  # helper method to remove all categories - do not run this if torrents already belong to live data
  def self.clear
    Category.delete_all
  end
  
  def self.create_defaults
    ['Television', 'Movies', 'Music', 'Anime', 'eBooks'].each do |name|
      Category.create_cat(name)
    end
  end
  
  def self.create_music
    ['Alternative', 'Blues', 'Classic Rock', 'Instrumental', 'Country', 'Dance', 'Trance', 'Hip-Hop', 'Latin', 'Pop', 'Emo', 'Rock'].each do |name|
      Category.create_cat(name)
    end
  end
  
  def self.create_cat(name)
    return if Category.find_by_name(name)
    Category.create!(:name => name)
  end

end
