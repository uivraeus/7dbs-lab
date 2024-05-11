require 'redis'
require 'redis/distributed'

TOTAL_NUMBER_OF_ENTRIES = ARGV[0].to_i

$redis = Redis::Distributed.new([
  "redis://localhost:6379/",
  "redis://redis-master:6379/"
])
$redis.flushall
count, start = 0, Time.now

(1..TOTAL_NUMBER_OF_ENTRIES).each do |n|
  count += 1
  
  key = "key#{n}"
  value = "value#{n}"

  $redis.set(key, value)

  break if count >= TOTAL_NUMBER_OF_ENTRIES
end
puts "#{count} items in #{Time.now - start} seconds"
