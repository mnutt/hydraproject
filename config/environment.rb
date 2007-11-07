# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end

# Include your application configuration below
require 'core_class_extensions'

require 'rubytorrent'

require 'rubygems'
gem 'memcache-client'

CACHE = MemCache.new 'localhost:11211', :namespace => 'hydra'

# Ensure memcached is running
begin
  CACHE.get('foo')
rescue MemCache::MemCacheError
  puts "\nStarting memcached...\n"
  system("memcached -d -m 64 -p 11211")
end

## Load global C (for Config) constant via config/config.yml and environment dependent YMLs

config_file = File.join(RAILS_ROOT, 'config', 'config.yml')
raise "Please copy config.yml.example to config.yml and modify per site." unless File.exist?(config_file)
c = YAML.load(IO.read(config_file))

# Convert any items prefixed with 'num_' to integer values.
c.each_pair do |k, v|
  if k[0..2] == 'num'
    c[k] = v.to_i
  end
end

c.symbolize_keys!
C = c

if 'test' != RAILS_ENV
  # For the Hydra Network; other trusted sites in this site's "federation"
  fed_file = File.join(RAILS_ROOT, 'config', 'federation.yml')
  if File.exist?(config_file)
    TRUSTED_SITES = YAML.load(IO.read(fed_file))
  else
    TRUSTED_SITES = []
  end
end

BASE_URL = "http://#{C[:domain_with_port]}/"

class TorrentFileNotFoundError < StandardError; end
