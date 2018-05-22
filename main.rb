require 'open-uri'
require 'nokogiri'
require 'set'
require 'benchmark'
require 'logger'

URL = "https://codegust.appspot.com/search?utf8=%E2%9C%93&q="
URL_GG = "https://www.google.com/search?q="
URL_SC = "https://searchcode.com/?q="
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
  logger = Logger.new('benchmark_nerd.log')
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
      logger.debug( query + ' s: '+ s.to_s)
      results[line.split.size] << s
    end
  end

  logger.close

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
  logger = Logger.new('random_queries.log')
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
        query << non_alpha(words[i])
      end
      query = query.join('+')
      s = 0.0
      (0...TRIES).each do
        doc = Nokogiri::HTML(open("#{URL}#{query}"))
        sleep(POLITENESS_POLICY_WAIT)
        s += doc.xpath("//*[@id='retrieval-time']").text.split[2].to_f
      end
      s /= TRIES.to_f
      logger.debug( query + ' s: '+ s.to_s)
      results[n] << s
    end
    File.open("random_queries_test_results.txt", "a") do |f|
      sum = results[n].inject(0){|s,x| s + x }
      avg = sum.to_f / TEST_PER_QUERY.to_f
      f.write("#{n}\t#{avg}\n")
    end
  end
  logger.close
end

def e2e_compare_nerd_terminologies
  results_cg = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}
  results_gg = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}
  results_sc = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}

  File.open("nerd_terminologies.txt", "r") do |f|
    f.each_line do |line|
      s_cg = 0.0
      s_gg = 0.0
      s_sc = 0.0
      query = non_alpha(line).gsub(' ', '+')
      (0...TRIES).each do
        start = Time.now
        Nokogiri::HTML(open("#{URL}#{query}"))
        finish = Time.now
        sleep(POLITENESS_POLICY_WAIT)
        s_cg += (finish-start).to_f

        start = Time.now
        Nokogiri::HTML(open("#{URL_GG}#{query}"))
        finish = Time.now
        sleep(POLITENESS_POLICY_WAIT)
        s_gg += (finish-start).to_f

        start = Time.now
        Nokogiri::HTML(open("#{URL_SC}#{query}"))
        finish = Time.now
        sleep(POLITENESS_POLICY_WAIT)
        s_sc += (finish-start).to_f
      end
      s_cg /= TRIES.to_f
      s_gg /= TRIES.to_f
      s_sc /= TRIES.to_f
      results_cg[line.split.size] << s_cg
      results_gg[line.split.size] << s_gg
      results_sc[line.split.size] << s_sc
    end
  end

  File.open("nerd_terminologies_e2e_compare_results.txt", "w") do |f|
    f.write("N\tcodeGUST\tGoogle\tsearchcode\n")
    (1..5).each do |i|
      avg_cg = (results_cg[i].inject(0){|s,x| s + x }).to_f / results_cg[i].length.to_f
      avg_gg = (results_gg[i].inject(0){|s,x| s + x }).to_f / results_gg[i].length.to_f
      avg_sc = (results_sc[i].inject(0){|s,x| s + x }).to_f / results_sc[i].length.to_f

      f.write("#{i}\t#{avg_cg}\t#{avg_gg}\t#{avg_sc}\n")
    end
  end
end

def e2e_compare_random_queries
  logger = Logger.new('e2e_random_queries.log')
  File.open("random_queries_e2e_compare_results.txt", "a") do |f|
    f.write("N\tcodeGUST\tGoogle\tsearchcode\n")
  end

  results_cg = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}
  results_gg = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}
  results_sc = {1=>[], 2=>[], 3=>[], 4=>[], 5=>[]}

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
        query << non_alpha(words[i])
      end
      query = query.join('+')
      logger.debug(query)
      f = true
      while f do
        begin
          s_cg = 0.0
          s_gg = 0.0
          s_sc = 0.0
          (0...TRIES).each do
            start = Time.now
            Nokogiri::HTML(open("#{URL}#{query}"))
            finish = Time.now
            sleep(POLITENESS_POLICY_WAIT)
            s_cg += (finish-start).to_f

            start = Time.now
            Nokogiri::HTML(open("#{URL_GG}#{query}"))
            finish = Time.now
            sleep(POLITENESS_POLICY_WAIT)
            s_gg += (finish-start).to_f

            start = Time.now
            Nokogiri::HTML(open("#{URL_SC}#{query}"))
            finish = Time.now
            sleep(POLITENESS_POLICY_WAIT)
            s_sc += (finish-start).to_f
          end
          s_cg /= TRIES.to_f
          s_gg /= TRIES.to_f
          s_sc /= TRIES.to_f
          results_cg[n] << s_cg
          results_gg[n] << s_gg
          results_sc[n] << s_sc
          f = false
        rescue Exception => e
          logger.debug(e.message)
          logger.debug(e.backtrace.inspect )
        end
      end
    end
    File.open("random_queries_e2e_compare_results.txt", "a") do |f|
      avg_cg = (results_cg[n].inject(0){|s,x| s + x }).to_f / TEST_PER_QUERY.to_f
      avg_gg = (results_gg[n].inject(0){|s,x| s + x }).to_f / TEST_PER_QUERY.to_f
      avg_sc = (results_sc[n].inject(0){|s,x| s + x }).to_f / TEST_PER_QUERY.to_f
      f.write("#{n}\t#{avg_cg}\t#{avg_gg}\t#{avg_sc}\n")
    end
  end
end

# benchmark_random_queries
# benchmark_nerd_terminologies
# e2e_compare_nerd_terminologies
e2e_compare_random_queries
