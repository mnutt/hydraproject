if ActiveSupport::Cache::MemCacheStore === ActionController::Base.cache_store
  # Ensure memcached is running
  begin
    Rails.cache.read('foo')
  rescue MemCache::MemCacheError
    puts "\nStarting memcached...\n"
    system("memcached -d -m #{C[:num_memcached_memory]} -p #{C[:num_memcached_port]}")
  end
end
