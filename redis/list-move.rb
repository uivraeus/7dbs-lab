require 'redis'

redis = Redis.new

redis.multi do
  site = redis.rpop('eric:wishlist')
  redis = redis.lpush('eric:visited', site)
end
