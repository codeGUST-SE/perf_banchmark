require 'open-uri'
require 'nokogiri'
require 'set'

URL = "https://codegust.appspot.com/search?utf8=%E2%9C%93&q="
POLITENESS_POLICY_WAIT = 0
TRIES = 3
TEST_PER_QUERY = 500

def rand_n(n, max)
  randoms = Set.new
  loop do
    randoms << rand(max-1)
    return randoms.to_a if randoms.size >= n
  end
end

def non_alpha(word)
    word.gsub(/[^a-z ]/i, '')
end

def benchmark_nerd_terminologies
  results = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}

  File.open("nerd_terminologies.txt", "r") do |f|
    f.each_line do |line|
      s = 0.0
      query = non_alpha(line.gsub(' ', '+'))
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

def benchmark_random_queries
  results = { 1=>[], 2=>[], 3=>[], 4=>[], 5=>[] }
  words = Set.new
  File.open("nerd_words.txt", "r") do |f|
    f.each_line do |word|
      words.add(word.downcase.strip)
    end
  end
  File.open("human_words.txt", "r") do |f|
    f.each_line do |word|
      words.add(word.strip)
    end
  end
  words = words.to_a
  for n in (1..5) do
    (0...TEST_PER_QUERY).each do
      query = []
      rand_n(n, words.size).each do |i|
        query << words[i]
      end
      query = query.join('+')
      puts query
    end
  end

end

benchmark_random_queries
