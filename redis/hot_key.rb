require 'redis'

def get_viral_product(redis, product_id, num_copies)
    suffix = rand(1..num_copies)

    key = "product:#{product_id}:#{suffix}"

    redis.get(key)
end

def update(redis, product_id, value, num_copies)
    (1..num_copies).each{|n|
        key = "product:#{product_id}:#{n}"
        redis.set(key, value)
    }
end

redis = Redis.new
# Fetch the viral product, spreading the load across 5 copies
puts get_viral_product(redis, "123", 5)
