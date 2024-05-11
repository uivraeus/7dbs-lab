require 'redis'
require 'bloomfilter-rb'

$redis = Redis.new(:host => "127.0.0.1", :port => 6379)
$redis.flushall
filter_matches = 0
false_positives = 0
cleaned_words = 0

bloomfilter = BloomFilter::Redis.new(:size => 1000000)
bloomfilter.clear

# we'll read the file data and strip out all the non-word material
text_data = File.read(ARGV[0])
clean_text = text_data.gsub(/\n/, ' ').gsub(/[,-.;'?"()!*]/, '')

clean_text.split(' ').each do |word|
  word = word.downcase
  cleaned_words += 1

  #next if bloomfilter.include?(word)
  if bloomfilter.include?(word)
    filter_matches += 1
    existing = $redis.get(word)
    false_positives += 1 if existing != "1"
  else
    puts word
    bloomfilter.insert(word)
    $redis.set(word, "1")
  end
end

puts "Total number of (cleaned) words: #{cleaned_words}"
puts "Number of words in filter: #{bloomfilter.size}"
puts "Number of filter matches: #{filter_matches}"
puts "Number of false positives: #{false_positives}"