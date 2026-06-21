require 'redis'
require 'time'

def allowed_to_make_request?(redis, user_id, limit)
  # 1. Generate the key for the current minute in UTC
  current_minute = Time.now.utc.strftime("%Y-%m-%d-%H:%M")
  key = "rate_limit:#{user_id}:#{current_minute}"

  # 2. Increment the counter for this key
  count = redis.incr(key)

  # 3. Check if the count exceeds our limit
  return false if count > limit
  
  # 4. If it's the first request, set the expiration
  if count == 1
    redis.expire(key, 60)
  end
end

# Connect to Redis
redis = Redis.new

# Let's say the limit is 5 requests per minute
puts allowed_to_make_request?(redis, "user_123", 5)
