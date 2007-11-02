require 'open-uri'
require 'htree'
require 'rexml/document'

url = "http://www.alexa.com/site/ds/top_sites?cc=US&ts_mode=country&lang=none"
open(url) do |page|
  page_content = page.read()
  doc = HTree(page_content).to_rexml
  doc.root.each_element('//a[@isdata="true"]') do |elem|
    puts elem.attribute('href').value
  end
end
