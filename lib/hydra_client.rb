require 'net/https'
require 'digest/sha1'

require 'rubygems'
gem 'activesupport', '>= 1.3.1'

require 'active_support'
require 'active_support/core_ext'

class HydraClient

  attr_accessor :url, :passkey, :port, :use_ssl, :use_curl, :curl_path
  
  UserAgent = 'Ruby HydraClient/1.0'
  
  # Usage:
  #   client = HydraClient.new('http://tracker.org/api', 'my-passkey')
  #   client.time # => "Sat Nov 18 08:41:44 UTC 2006"
  #   client.list_torrents(500)  # lists torrents since 500 seconds ago
  def initialize(url, passkey, options = {})
    @url, @passkey, @options = url, passkey, options
    
    # Set defaults
    @port = 80
    @use_ssl = true

    # curl config
    @use_curl = true
    @curl_path = 'curl'

    # Set any other instance variables based on the options specified
    @options.each { |pref, value| instance_variable_set("@#{pref}", value) }
    
    connect! if !@use_curl
  end
  
  def time
    request('time')
  end
  
  def list_users(since)
    if since <= 0
      return request('list_users', {'first_load' => 'true'})
    end
    return request('list_users', {'since' => since})
  end
  
  def list_transfer_stats(last_sync_id = nil)
    return request('list_transfer_stats', {'first_load' => 'true'}) if last_sync_id.nil?
    return request('list_transfer_stats', {'last_sync_id' => last_sync_id})
  end
  
  def list_torrents(since)
    return request('list_torrents', {'first_load' => 'true'}) if since <= 0
    return request('list_torrents', {'since' => since})
  end
  
  def get_torrent(info_hash, output_path)
    success, reason = grab_torrent(info_hash, output_path)
    if !success
      return false, reason
    end

    begin
      mi = RubyTorrent::MetaInfo.from_location(output_path)
    rescue RubyTorrent::MetaInfoFormatError, RubyTorrent::BEncodingError => e
      return false, "Couldn't parse #{output_path}: maybe not a .torrent file?"
    end
    
    return true
  end
  
  private

  def request(method, params = {})
    return curl_request(method, params) if @use_curl
    return net_http_request(method, params)
  end

  def curl_request(method, params = {})
    full_url = construct_full_url(method)
    
    params['passkey'] = @passkey
    
    data = ''
    params.each_pair do |k,v|
      data << "#{k}=#{v}&"
    end

    data = "-d '#{data}'"

    cmd = "#{@curl_path} #{data} #{full_url}"
    puts "CURL: #{cmd}"
    
    curl = IO.popen(cmd)
    result = curl.read
    curl.close_read
    puts "CURL Result: #{result}"
    begin
      hash = Hash.from_xml(result.strip)
    rescue StandardError => e
      puts "Rescued Error: #{e}"
      puts "Exception while parsing result: #{e}"
      hash = nil
    end
    puts "Returning: #{hash}"
    return hash
  end

  def grab_torrent(info_hash, output_path)
    url = "#{@url}?method=get_torrent&info_hash=#{info_hash}"
    curl = "curl -d \"passkey=#{@passkey}\" -m 10 --output \"#{output_path}\" --user-agent \"#{UserAgent}\" --connect-timeout 10 \"#{url}\""
    puts "\n\tCURL: #{curl}"
    `#{curl}`
    
    return false unless File.exist?(output_path)
    contents = IO.read(output_path)
    puts "\n\n\nTorrent File Contents:\n#{contents}\n\n\n"
    if contents =~ /auth_failed/
      return false, 'Authentication failed'
    elsif contents =~ /not_found/
      return false, 'Torrent not found'
    end
    return true
  end

  # Make a raw request to the API. This will return a Hash of
  # Arrays of the response.
  def net_http_request(path, params = {})
    hash = nil
    body = params_to_xml(params)
    puts "NET HTTP REQUEST.  body = #{body}"
    response = post('api/' + path, body, 'Content-Type' => 'application/xml')
    puts "response = #{response.inspect}"
    raise "Exception occurred when calling #{path} with #{params.inspect}" if response.nil?
    if response.code.to_i == 200
      begin
        hash = Hash.from_xml(result)
      rescue StandardError => e
        puts "Exception while parsing result: #{e}"
      end
    else
      raise "#{response.message} (#{response.code})"
    end
    return hash
  end
    
  def connect!
    puts "Connecting : #{url}"
    @connection = Net::HTTP.new(@url, @use_ssl ? 443 : @port)
    @connection.use_ssl = @use_ssl if @use_ssl
    @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE if @use_ssl
    puts "@connection = #{@connection}"
  end

  def post(path, body, headers={})
    puts "post: path = #{path}, body = #{body}, headers = #{headers.inspect}"
    begin
      request = Net::HTTP::Post.new(path, headers.merge('Accept' => 'application/xml'))
      puts "request = #{request}"
      return @connection.request(request, body)
    rescue StandardError => e
      puts "\tException in post: #{e}"
      return nil
    end
  end
  
  def params_to_xml(params = {})
    if !params.empty?
      str = params.to_xml({:skip_instruct => true, :root => 'request'})
      # Ugly hack - to_xml requires that the Hash be wrapped in a node, i.e. '<request><contact>...</contact></request>'
      #  Strip out the request tags:
      str.sub!(/^<request>/, '')
      str.sub!(/<\/request>$/, '')
      str.strip!
    else
      str = ''
    end
    return str
  end
  
  def construct_full_url(method)
    return "#{@url}?method=#{method}"
  end
  
  # Salt a random SHA1 hash (salted with both the current time and a random number)
  def get_rand_output_fname
    r = rand(1000000000)
    return Digest::SHA1.hexdigest("#{Time.now.to_i}-----#{r}")
  end

end