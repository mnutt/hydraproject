require 'digest/sha1'

Factory.define :torrent do |t|
  t.name "My Torrent"
  t.filename "mytorrent.torrent"
  t.info_hash "a50246b2d98527a881fad7e24c603d0c5ee3bae4"
  t.size 20267076
  t.piece_length 32768
  t.pieces 927
  t.torrent_comment "This is my torrent"
  t.orig_announce_url "http://hydra.local/tracker/0f113f1de4/announce"
  t.created_by "Transmission/1.34 (6770)"
  t.description "Torrent description"
  t.seeders 4
  t.leechers 10
  t.association :user
  t.the_file { 
    @file = File.new("#{RAILS_ROOT}/spec/data/test.torrent")
    def @file.original_filename; "name.torrent"; end
    @file
  }
end

Factory.define :peer do |p|
  p.peer_id "-TR1340-z2p3bqdigydk"
  p.port 51413
  p.passkey "97e9092f4b"
  p.seeder true
  p.connectable true
end

Factory.define :user do |u|
  u.login "quentin"
  u.email "quentin@example.com"
  u.salt { Digest::SHA1.hexdigest('0') }
  u.crypted_password "f9c8634b5ef30b4047c4ce34bd703fafb3e6be9a" # monkey
  u.created_at { 5.days.ago }
  u.remember_token_expires_at { 1.days.from_now }
  u.remember_token "77de68daecd823babbb58edb1c8e14d7106e83bb"
  u.activated_at { 5.days.ago }
  u.age_verify "1"
end

Factory.define :unactivated_user, :class => User do |u|
  u.login "aaron"
  u.email "aaron@example.com"
  u.salt { Digest::SHA1.hexdigest('0') }
  u.crypted_password "f9c8634b5ef30b4047c4ce34bd703fafb3e6be9a" # monkey
  u.created_at { 1.days.ago }
  u.activation_code "1b6453892473a467d07372d45eb05abc2031647a"
  u.age_verify "1"
end

Factory.define :admin_user, :class => User do |u|
  u.login "admin"
  u.email "admin@example.com"
  u.salt { Digest::SHA1.hexdigest('0') }
  u.crypted_password "f9c8634b5ef30b4047c4ce34bd703fafb3e6be9a" # monkey
  u.created_at { 5.days.ago }
  u.remember_token_expires_at { 1.days.from_now }
  u.remember_token "77de68daecd823babbb58edb1c8e14d7106e83bb"
  u.activated_at { 5.days.ago }
  u.age_verify "1"
  u.is_admin true
end

Factory.define :category do |c|
  c.name "Files"
end

Factory.define :feed do |f|
  f.url "http://feeds.feedburner.com/AmbientOfficeNoises"
  f.user { Factory.create(:user) }
end
