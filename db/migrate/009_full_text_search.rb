class FullTextSearch < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE torrents ENGINE = MyISAM'
    execute 'CREATE FULLTEXT INDEX ft_idx_torrents ON torrents(name,filename,description)'
  end

  def self.down
    execute 'ALTER TABLE torrents DROP INDEX ft_idx_torrents'
    execute 'ALTER TABLE torrents ENGINE = InnoDB'
  end
end
