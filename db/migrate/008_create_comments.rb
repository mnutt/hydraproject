class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :comment, :text
      t.column :torrent_id, :integer
      t.column :user_id, :integer
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :comments
  end
end
