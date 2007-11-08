class IsLocal < ActiveRecord::Migration
  def self.up
    add_column :users, :is_local, :boolean, :default => true
    execute 'UPDATE users SET is_local=1'
  end

  def self.down
    remove_column :users, :is_local
  end
end
