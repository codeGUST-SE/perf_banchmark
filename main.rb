require 'open-uri'
require 'nokogiri'

URL = "https://codegust.appspot.com/search?utf8=%E2%9C%93&q="
POLITENESS_POLICY_WAIT = 0
TRIES = 3

def non_alpha(word)
    word.gsub(/[^a-z ]/i, '')
end

def benchmark_nerd_terminologies
  results = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}

  File.open("nerd_terminologies.txt", "r") do |f|
    f.each_line do |line|
      s = 0.0
      query = non_alpha(line).gsub(' ', '+')
      (0...TRIES).each do
        doc = Nokogiri::HTML(open("#{URL}#{query}"))
        sleep(POLITENESS_POLICY_WAIT)
        s += doc.xpath("//*[@id='retrieval-time']").text.split[2].to_f
      end
      s /= TRIES.to_f
      results[line.split.size] << s
    end
  end

  File.open("nerd_terminologies_test_results.txt", "w") do |f|
    results.each do |key, value|
      sum = value.inject(0){|s,x| s + x }
      n = value.length
      avg = sum.to_f / n.to_f
      f.write("#{key}\t#{avg}\n")
    end
  end
end

benchmark_nerd_terminologies
