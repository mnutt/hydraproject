class AddUserToResources < ActiveRecord::Migration
  def self.up
    add_column :resources, :user_id, :integer
  end

  def self.down
    remove_column :resources, :user_id
  end
end
