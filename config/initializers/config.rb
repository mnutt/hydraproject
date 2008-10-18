## Load global C (for Config) constant via config/config.yml and environment dependent YMLs
CONFIG_FILE = File.join(RAILS_ROOT, 'config', 'config.yml')
raise "Please copy config.yml.example to config.yml and modify per site." unless File.exist?(CONFIG_FILE)
c = YAML.load(IO.read(CONFIG_FILE))

# Convert any items prefixed with 'num_' to integer values.
c.each_pair do |k, v|
  if k[0..2] == 'num'
    c[k] = v.to_i
  end
end

c.symbolize_keys!
C = c
