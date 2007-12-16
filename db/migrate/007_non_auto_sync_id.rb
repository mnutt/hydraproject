class NonAutoSyncId < ActiveRecord::Migration
  def self.up
    remove_column :ratio_syncs, :id
    add_column :ratio_syncs, :sync_id, :integer  # NOTE: this cannot be an Auto-generated ID field b/c it's shared on Both sides (each site)
    add_index :ratio_syncs, [:domain, :sync_id], :name => "rs_domain_sync_id", :unique => true
  end

  def self.down
    add_column :ratio_syncs, :id, :integer
    remove_column :ratio_syncs, :sync_id
    remove_index :ratio_syncs, :name => 'rs_domain_sync_id'
  end
end
