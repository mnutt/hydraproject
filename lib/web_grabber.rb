require 'net/http'
require 'md5'

class WebGrabber
  
  attr_reader :url
  
  USER_AGENT = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; Media Center PC 4.0)"
  FIREFOX_USER_AGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.6) Gecko/20060728 Firefox/1.5.0.6"
  
  def initialize(url, options = {})
    @url = url
    
    @use_curl = true
    # -c/--cookie-jar <file> Write cookies to this file after operation
    @cookie_jar = options[:cookie_jar] || nil
    
    # -b/--cookie <name=string/file> Cookie string or file to read cookies from
    @cookie_file = options[:cookie_file] || nil
  end

  ## STATIC METHODS
  def self.grab_image(url, outpath)
    curl = "curl -m 10 --output \"#{outpath}\" --cookie \"cookie-jar.txt\" --user-agent \"#{FIREFOX_USER_AGENT}\" --connect-timeout 3 \"#{url}\""
    puts "\n\tCURL: #{curl}"
    `#{curl}`
  end
  
  ## MEMBER METHODS
  
  def cache_file
    md5 = MD5::new(self.url)
    return "/tmp/#{md5}"
  end
  
  def get_data_via_curl
    output_path = cache_file
    jar = @cookie_jar ? "--cookie-jar \"#{@cookie_jar}\"" : ''
    cookie_file = @cookie_file ? "--cookie \"#{@cookie_file}\"" : ''
    max_timeout = "--connect-timeout 5 --max-time 15"
    curl = "curl --silent --location --output \"#{output_path}\" #{cookie_file} #{jar} --user-agent \"#{FIREFOX_USER_AGENT}\" #{max_timeout} \"#{self.url}\""
    #puts "\n\nCalling: #{curl}\n\n"
    `#{curl}`
    if File.exists?(output_path)
      return @_data = IO.read(self.cache_file)
    end
    return nil
  end
  
  def fetch
    get_data_via_curl
  end
  
  def data
    return @_data if @_data
    return get_data_via_curl if @use_curl
    
    response = Net::HTTP.get_with_headers(self.url, {'User-Agent' => USER_AGENT })
    return nil if response.nil?
    
    if response == Net::HTTPRedirection
      response = Net::HTTP.get_with_headers(response['location'], {'User-Agent' => USER_AGENT })
    end
    size = response.body.size
    body = nil
    if response.code.to_i == 200
      #puts "\tSize: #{size}\t Body: #{response.body[0, 50]}..."
      body = response.body
    else
      #logger.info "\tError getting body: #{response.code}"
    end
    return @_data = body
  end
  
  def extract_links(type = 'http')
    contents = self.data
    extracted_links = (contents.nil?) ? [] : URI.extract(contents, [type])
    return extracted_links
  end
  
  def extract_mailtos
    self.extract_links('mailto')
  end

  def youtube_links
    return [] unless self.data
    site_links = self.data.scan(/<a href=\"(.*?)\"/).flatten
    youtube_urls = []
    site_links.each do |sl|
      if sl =~ /^\/watch\?v=/
        youtube_urls << "http://youtube.com#{sl}"
        next
      end
      if sl =~ /youtube\.com\/watch\?v=/ 
        youtube_urls << sl
      end
    end
    youtube_urls.uniq!
    return youtube_urls
  end
  
  def title
    title = nil
    contents = self.data
    if contents
      titles = contents.scan(/<\s*title\s*>(.*)<\s*\/title\s*>/mi) 
      titles.flatten!
      if !titles.empty?
        title = titles.first
        title.strip!
      end
    end
    return title
  end
  
end
