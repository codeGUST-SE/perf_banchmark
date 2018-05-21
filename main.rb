require 'open-uri'
require 'nokogiri'

doc = Nokogiri::HTML(open("https://github.com/codeGUST-SE/crawler/blob/master/main.rb"))

puts doc