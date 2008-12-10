class AddContentToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :content, :text
  end

  def self.down
    remove_column :feeds, :content
  end
end
