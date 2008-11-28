class AddFullTextToTorrents < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "mysql"
      remove_index "torrents", :name => "ft_idx_torrents"
      execute("ALTER TABLE torrents ENGINE = MyISAM")
      execute("CREATE FULLTEXT INDEX FullText_torrents ON torrents (`name`, `filename`, `description`);")
    end
  end

  def self.down
    add_index "torrents", ['name', 'filename'], :name => 'ft_idx_torrents'
    remove_index "torrents", :name => "FullText_torrents"
  end
end
