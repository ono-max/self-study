require 'redis'

def update_post_score(redis, keyword, post_id, likes)
  key = "leaderboard:#{keyword}"
  
  # 1. Add or update the post in the sorted set with its new like count
  # ???
  redis.zadd(key, likes, post_id)

  redis.zremrangebyrank(key, 0, -6)
  
  puts "Updated #{post_id} with #{likes} likes!"
end

redis = Redis.new
update_post_score(redis, "tiger", "post_99", 500)
