class AddUrlListToTorrents < ActiveRecord::Migration
  def self.up
    add_column :torrents, :url_list, :string
  end

  def self.down
    remove_column :torrents, :url_list
  end
end
