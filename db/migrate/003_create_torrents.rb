class CreateTorrents < ActiveRecord::Migration
  def self.up
    create_table :torrents do |t|
      t.column :info_hash, :string
      t.column :name, :string
      t.column :user_id, :integer  # NOTE: this is *only* temporarily set.  It should get unset automatically
      t.column :filename, :string  #   after the admin/users have verified the torrent.
      t.column :original_filename, :string
      t.column :description, :text
      t.column :category_id, :integer
      t.column :size, :integer      # in bytes
      t.column :piece_length, :integer
      t.column :pieces, :integer
      t.column :orig_announce_url, :string
      t.column :orig_announce_list, :text
      t.column :created_by, :string           # Torrent Client 'created by' String identifier
      t.column :torrent_comment, :string
      t.column :numfiles, :integer
      t.column :views, :integer, :default => 0
      t.column :times_completed, :integer, :default => 0
      t.column :leechers, :integer, :default => 0
      t.column :seeders, :integer, :default => 0
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end

    add_index :torrents, :info_hash

    create_table :torrent_files do |t|
      t.column :torrent_id, :integer
      t.column :filename, :text
      t.column :size, :integer
    end
    
    # Note:  Peer IPs are *NOT* kept in the database.  They are kept in memcached, meaning, they are lost upon
    #  a server reboot / restart.
    create_table :peers do |t|
      t.column :torrent_id, :integer
      t.column :peer_id, :string
      t.column :port, :integer
      t.column :passkey, :string
      t.column :uploaded, :integer, :default => 0
      t.column :downloaded, :integer, :default => 0
      t.column :to_go, :integer, :default => 0
      t.column :seeder, :boolean, :default => false
      t.column :connectable, :boolean, :default => false
      t.column :user_id, :integer
      t.column :agent, :string
      t.column :finished_at, :datetime
      t.column :download_offset, :integer, :default => 0
      t.column :upload_offset, :integer, :default => 0
      t.column :last_action_at, :datetime
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    add_index :peers, [:torrent_id, :peer_id], :unique => true
    add_index :peers, :connectable
  end

  def self.down
    drop_table :torrents
    drop_table :torrent_files
    drop_table :peers
    remove_index :torrents, :column_name
    remove_index :peers, :column => :column_name
    remove_index :peers, :column_name
  end
end
