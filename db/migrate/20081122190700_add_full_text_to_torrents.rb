class AddFullTextToTorrents < ActiveRecord::Migration
  def self.up
  #  remove_index "torrents", :name => "ft_idx_torrents"
    execute("CREATE FULLTEXT INDEX ft_idx_torrents ON torrents (`name`, `filename`, `description`);")
  #  add_index "torrents", ["name", "filename", "description"], :name => "ft_idx_torrents"
  end

  def self.down
  end
end
