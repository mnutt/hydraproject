ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  map.with_options :controller => 'home' do |m|
    m.index             '',                                     :action => 'index'
  end

  map.with_options :controller => 'torrent' do |m|
    m.download          'download/:id/:filename',               :action => 'download'
  end

  map.with_options :controller => 'tracker' do |m|
    m.announce          'tracker/:passkey/announce',            :action => 'announce'
    m.scrape            'tracker/:passkey/scrape',              :action => 'scrape'
  end
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
