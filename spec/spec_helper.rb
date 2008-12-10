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
end

include AuthenticatedTestHelper

# Meta-fixture here
TRUSTED_SITES = [{:domain => 'foo.org', 
                  :passkey => 'foo123', 
                  :api_url => 'http://foo.org/api', 
                  :announce_url => 'http://foo.org/announce'}] unless defined?(TRUSTED_SITES)

require File.expand_path(File.dirname(__FILE__) + "/factories.rb")

mock_config = {:require_email => true}
permissions = {:user      => [:view, :download, :upload],
               :anonymous => [:view, :download],
               :admin     => [:view, :download, :upload, :web_seed]}
mock_config.merge!(:permissions => permissions)
Object.send(:remove_const, :C)
C = mock_config
