ActionController::Routing::Routes.draw do |map|
  # User routes
  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login',  :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.register '/register', :controller => 'users', :action => 'create'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.resources :users
  map.resource  :session

  map.resources :torrents, :collection => {:search => :any}
  map.resources :resources

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
