class Initial < ActiveRecord::Migration
  def self.up
    
    create_table :users, :force => true do |t|
      t.column :login,                  :string
      t.column :hashed_password,        :string
      t.column :salt,                   :string
      t.column :is_admin,               :boolean,  :default => false
      t.column :is_editor,              :boolean,  :default => false
      t.column :remember_token,         :string
      t.column :remember_token_expires, :datetime
      t.column :created_at,             :datetime
      t.column :updated_at,             :datetime
    end
    
  end

  def self.down
    drop_table :users
  end
end
