ActionController::Routing::Routes.draw do |map|

  map.with_options :controller => 'torrent', :action => 'download', :requirements => { :filename => /.*/ } do |m|
    m.download          'download/:id/:filename'               
    m.feed_download     'feed_download/:id/:passkey/:filename'
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
