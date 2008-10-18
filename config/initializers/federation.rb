if 'test' != RAILS_ENV
  # For the Hydra Network; other trusted sites in this site's "federation"
  fed_file = File.join(RAILS_ROOT, 'config', 'federation.yml')
  if File.exist?(CONFIG_FILE)
    sites = YAML.load(IO.read(fed_file))
    if sites.nil?
      TRUSTED_SITES = []
    else
      symbolized = []
      sites.each do |hash|
        symbolized << hash.symbolize_keys
      end
      TRUSTED_SITES = symbolized.freeze
    end
  else
    TRUSTED_SITES = []
  end

  TRUSTED_SITES.each do |site|
    unless site[:domain] && site[:passkey] && site[:api_url]
      raise InvalidTrustedSiteFormat, "Site must have keys 'domain', 'passkey' and 'api_url' : #{site.inspect}"
    end
  end
end
