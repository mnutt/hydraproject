xml.rss(:version => '2.0') do
  xml.channel do
    xml.title @title
    xml.link BASE_URL
    xml.description @description
    @torrents.each do |t|
      xml.item do
        @download_url = torrent_dl_passkey(t, @user.passkey)
        xml.title t.name
        xml.guid @download_url, :isPermaLink => true
        xml.link @download_url
        xml << "<description><![CDATA[#{t.description || ''} \n\r ]]></description>" if !t.description.blank?
        xml << "<enclosure url=\"#{@download_url}\" length=\"-1\" type=\"application/x-bittorrent\" />"
        xml.pubDate t.created_at.strftime('%a, %d %b %Y %H:%M:%S %z')
      end
    end
  end
end
