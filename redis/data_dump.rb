require 'redis'
#%w{hiredis redis/connection/hiredis}.each{|r| require r}

# the number of set operations to perform will be defined as a CLI arg
TOTAL_NUMBER_OF_ENTRIES = ARGV[0].to_i

$redis = Redis.new(:host => "127.0.0.1", :port => 6379)
$redis.flushall
count, start = 0, Time.now

(1..TOTAL_NUMBER_OF_ENTRIES).each do |n|
  count += 1

  key = "key#{n}"
  value = "value#{n}"

  $redis.set(key, value)

  # stop iterating when we reach the specified number
  break if count >= TOTAL_NUMBER_OF_ENTRIES
end
puts "#{count} items in #{Time.now - start} seconds"
