ActionController::Routing::Routes.draw do |map|
  map.resources :torrents

  map.with_options :controller => 'torrents', :action => 'download', :requirements => { :filename => /.*/ } do |m|
    m.download          'torrent/:id/download/:filename'               
    m.feed_download     'torrent/:id/feed_download/:passkey/:filename'
  end

  map.with_options :controller => 'tracker' do |m|
    m.announce          'tracker/:passkey/announce',            :action => 'announce'
    m.scrape            'tracker/:passkey/scrape',              :action => 'scrape'
  end

  map.root :controller => 'home', :action => 'index'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
