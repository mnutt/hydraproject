namespace :hydra do
  task :prepare do
    ['database.yml', 'config.yml', 'federation.yml'].each do |config_file|
      unless File.exist?("#{RAILS_ROOT}/config/#{config_file}")
        `cp #{RAILS_ROOT}/config/#{config_file}.example #{RAILS_ROOT}/config/#{config_file}`
      end
    end
  end
  task :first_sync => :environment do
    Sync.first_sync
  end
end
