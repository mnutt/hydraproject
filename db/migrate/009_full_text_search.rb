class FullTextSearch < ActiveRecord::Migration
  def self.up
    #if ActiveRecord::Base.configurations[ENV['RAILS_ENV']]["adapter"] == "mysql"
      execute 'ALTER TABLE torrents ENGINE = MyISAM'
      execute 'CREATE FULLTEXT INDEX ft_idx_torrents ON torrents(name,filename)'
    #end
  end

  def self.down
    #if ActiveRecord::Base.configurations[ENV['RAILS_ENV']]["adapter"] == "mysql"
      execute 'ALTER TABLE torrents DROP INDEX ft_idx_torrents'
      execute 'ALTER TABLE torrents ENGINE = InnoDB'
    #end
  end
end
