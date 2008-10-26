class AddResourceIdToTorrents < ActiveRecord::Migration
  def self.up
    add_column :torrents, :resource_id, :integer
    remove_column :resources, :torrent_id
  end

  def self.down
    remove_column :torrents, :resource_id
  end
end
