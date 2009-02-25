class Feed < ActiveRecord::Base
  class InvalidAddressException < Exception; def message; "That's not a web address." end end
  class NoEnclosureException    < Exception; def message; "That's a text RSS feed, not an audio or video podcast." end end

  belongs_to :user
  has_many :resources

  def refresh
    fetch_content
    parse
    create_resources
    save
  end

  def fetch_content
    raise InvalidAddressException unless self.url =~ %r{^([^/]*//)?([^/]+)}

    Timeout::timeout(5) do
      OpenURI::open_uri(self.url, "User-Agent" => "Hydra/0.1") do |f|
        self.content = f.read
      end
    end
  rescue NoMethodError
    raise InvalidAddressException
  rescue Timeout::Error
    raise "Timed out"
  end

  def parse
    begin
      @feed = RPodcast::Feed.new(content)
    rescue RPodcast::NoEnclosureError
      raise NoEnclosureException
    end
  end

  def create_resources
    @feed.episodes.each do |episode|
      next if episode.enclosure.nil? or episode.enclosure.url.nil?
      file = URLTempfile.new(episode.enclosure.url)
      resource = self.resources.build(:file => file, :user_id => self.user_id)
      resource.save!

      self.content.gsub!(%r{#{episode.enclosure.url}}, "http://#{C[:domain_with_port]}/torrent/#{resource.torrent.id}/download/#{resource.torrent.filename}")
    end
  end

  def rfeed
    @feed
  end
end
