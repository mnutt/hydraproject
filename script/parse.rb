require 'rubygems'
require 'hpricot'
require 'open-uri'

#doc = Hpricot(open('http://www.alexa.com/site/ds/top_sites?cc=US&ts_mode=country&lang=none'))
doc = open("quantcast.html") { |f| Hpricot(f) }

puts doc.inspect
#links = doc/"//a[isdata='true']"
#links = doc/"/table//a"
links = doc/"//a"
puts links.inspect

#map = Hash.new
urls = Array.new
links.each do |ele|
  puts "Inspected: #{ele.inspect}"
  puts "#{ele.class}"
  urls << ele.attributes['href']
end

urls.delete_if do |key| 
  key.include?('http://') || key.include?('/') || key.include?('top-sites') || key.include?('javascript')
end

urls.each do |key|
  puts "#{key}"
end
