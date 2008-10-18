# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
end

# Meta-fixture here
TRUSTED_SITES = [{'domain' => 'foo.org', 'passkey' => 'foo123', 'api_url' => 'http://foo.org/api'}]

require 'factory-girl'
require File.expand_path(File.dirname(__FILE__) + "/factories.rb"
