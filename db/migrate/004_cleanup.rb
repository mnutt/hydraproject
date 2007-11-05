class Cleanup < ActiveRecord::Migration
  def self.up
    remove_column :torrents, :original_filename
    rename_column :users, :is_editor, :is_moderator
    add_column :users, :passkey, :string
    
    User.find(:all).each do |u|
      u.generate_passkey!
    end
    
    add_column :users, :uploaded, :integer, :default => 0
    add_column :users, :downloaded, :integer, :default => 0
    
  end

  def self.down
    add_column :torrents, :original_filename,  :string
    rename_column :users, :is_moderator, :is_editor
    remove_column :users, :passkey
    remove_column :users, :uploaded
    remove_column :users, :downloaded
  end
end
