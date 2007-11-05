class Cleanup < ActiveRecord::Migration
  def self.up
    remove_column :torrents, :original_filename
    rename_column :users, :is_editor, :is_moderator
    add_column :users, :passkey, :string
    
    User.find(:all).each do |u|
      u.generate_passkey!
    end
    
  end

  def self.down
    add_column :torrents, :original_filename,  :string
    rename_column :users, :is_moderator
    remove_column :users, :passkey
  end
end
