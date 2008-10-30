# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'
require 'factory_girl'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
end

include AuthenticatedTestHelper

# Meta-fixture here
TRUSTED_SITES = [{'domain' => 'foo.org', 'passkey' => 'foo123', 'api_url' => 'http://foo.org/api'}] unless defined?(TRUSTED_SITES)

require File.expand_path(File.dirname(__FILE__) + "/factories.rb")

# Mock out MemCache
class MemCacheMock
  @@cache = {}

  class << self
    def get(key)
      @cache[key] if @cache.has_key?(key)
    end
    def set(key, value)
      @cache[key] = value
    end
    def delete(key)
      @cache.delete(key)
    end
    def reset
      @cache = {}
    end
  end
end
CACHE = MemCacheMock unless defined?(CACHE)

mock_config = {:require_email => true}
Object.send(:remove_const, :C)
C = mock_config
