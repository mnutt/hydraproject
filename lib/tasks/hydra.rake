namespace :hydra do
  task :first_sync => :environment do
    Sync.first_sync
  end
end
