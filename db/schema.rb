# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081210054856) do

  create_table "categories", :force => true do |t|
    t.string "name"
  end

  create_table "comments", :force => true do |t|
    t.text     "comment"
    t.integer  "torrent_id"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  create_table "feeds", :force => true do |t|
    t.string   "url"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "content"
  end

  create_table "peers", :force => true do |t|
    t.integer  "torrent_id"
    t.string   "peer_id"
    t.integer  "port"
    t.string   "passkey"
    t.integer  "uploaded",        :default => 0
    t.integer  "downloaded",      :default => 0
    t.integer  "to_go",           :default => 0
    t.boolean  "seeder",          :default => false
    t.boolean  "connectable",     :default => false
    t.integer  "user_id"
    t.string   "agent"
    t.datetime "finished_at"
    t.integer  "download_offset", :default => 0
    t.integer  "upload_offset",   :default => 0
    t.datetime "last_action_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "peers", ["torrent_id", "peer_id"], :name => "index_peers_on_torrent_id_and_peer_id", :unique => true
  add_index "peers", ["connectable"], :name => "index_peers_on_connectable"

  create_table "ratio_snapshots", :force => true do |t|
    t.integer  "ratio_sync_id"
    t.integer  "user_id"
    t.string   "login"
    t.integer  "downloaded",    :default => 0
    t.integer  "uploaded",      :default => 0
    t.datetime "created_at"
  end

  create_table "ratio_syncs", :id => false, :force => true do |t|
    t.string   "domain"
    t.datetime "created_at"
    t.integer  "sync_id"
  end

  add_index "ratio_syncs", ["domain", "sync_id"], :name => "rs_domain_sync_id", :unique => true

  create_table "resources", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "feed_id"
  end

  create_table "torrent_files", :force => true do |t|
    t.integer "torrent_id"
    t.text    "filename"
    t.integer "size"
  end

  create_table "torrents", :force => true do |t|
    t.string   "info_hash"
    t.string   "name"
    t.integer  "user_id"
    t.string   "filename"
    t.text     "description"
    t.integer  "category_id"
    t.integer  "size"
    t.integer  "piece_length"
    t.integer  "pieces"
    t.string   "orig_announce_url"
    t.text     "orig_announce_list"
    t.string   "created_by"
    t.string   "torrent_comment"
    t.integer  "numfiles"
    t.integer  "views",              :default => 0
    t.integer  "times_completed",    :default => 0
    t.integer  "leechers",           :default => 0
    t.integer  "seeders",            :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "resource_id"
    t.string   "url_list"
  end

  add_index "torrents", ["info_hash"], :name => "index_torrents_on_info_hash"

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.boolean  "is_admin",                                 :default => false
    t.boolean  "is_moderator",                             :default => false
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "passkey"
    t.integer  "uploaded",                                 :default => 0
    t.integer  "downloaded",                               :default => 0
    t.integer  "downloaded_local",                         :default => 0
    t.integer  "uploaded_local",                           :default => 0
    t.boolean  "is_local",                                 :default => true
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
