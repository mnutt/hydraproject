Dir.glob("#{RAILS_ROOT}/vendor/gems/**/lib").each do |dir|
  $LOAD_PATH.unshift File.expand_path(dir)
end
