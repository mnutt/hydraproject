class RatioSync < ActiveRecord::Migration
  def self.up
    create_table :ratio_syncs do |t|
      t.column :domain, :string
      t.column :created_at, :datetime
    end
    
    create_table :ratio_snapshots do |t|
      t.column :ratio_sync_id, :integer
      t.column :user_id, :integer
      t.column :login, :string
      t.column :downloaded, :integer, :default => 0
      t.column :uploaded, :integer, :default => 0
      t.column :created_at, :datetime
    end
    
    # We need to track, in addition to the global UL/DL ratio, the LOCAL uploaded/downloaded amounts individually,
    #  which might diverge from the master UL/DL which incorporates xfer bytes from all servers.
    add_column :users, :downloaded_local, :integer, :default => 0
    add_column :users, :uploaded_local, :integer, :default => 0
    execute 'UPDATE users SET downloaded_local=0'
    execute 'UPDATE users SET uploaded_local=0'
  end

  def self.down
    drop_table :ratio_syncs
    drop_table :ratio_snapshot
    remove_column :users, :downloaded_local
    remove_column :users, :uploaded_local
  end
end
