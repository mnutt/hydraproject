class CreateUsers < ActiveRecord::Migration
  def self.up
    change_column :users, :login,       :string, :limit => 40
    add_column    :users, :name,        :string, :limit => 100, :default => '', :null => true
    add_column    :users, :email,       :string, :limit => 100
    rename_column :users, :hashed_password, :crypted_password
    change_column :users, :crypted_password, :string, :limit => 40
    change_column :users, :salt,        :string, :limit => 40
    change_column :users, :remember_token,         :string, :limit => 40
    rename_column :users, :remember_token_expires, :remember_token_expires_at
    add_column    :users, :activation_code,        :string, :limit => 40
    add_column    :users, :activated_at,           :datetime

    add_index :users, :login, :unique => true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
