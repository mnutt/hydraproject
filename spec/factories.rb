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
end
