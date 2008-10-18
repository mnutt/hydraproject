CACHE = MemCache.new "localhost:#{C[:num_memcached_port]}", :namespace => 'hydra'

# Ensure memcached is running
begin
  CACHE.get('foo')
rescue MemCache::MemCacheError
  puts "\nStarting memcached...\n"
  system("memcached -d -m #{C[:num_memcached_memory]} -p #{C[:num_memcached_port]}")
end
