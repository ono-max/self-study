require 'redis'
require 'securerandom'

def acquire_lock(redis, lock_key, timeout_seconds)
    token = SecureRandom.uuid

    # Attempt to set the key with NX and EX flags
    success = redis.set(lock_key, token, nx: true, ex: timeout_seconds)

    if success
        puts "Lock acquired! Token: #{token}"
        return token
    else
        puts "Failed to acquire lock. Someone else has it."
        return false
    end
end

SCRIPT = <<-LUA
    if redis.call('GET', KEYS[1]) == ARGV[1] then
        return redis.call('DEL', KEYS[1])
    end
LUA

def release_lock(redis, lock_key, token)
    redis.eval(SCRIPT, keys: [lock_key], argv: [token])
end

redis = Redis.new
acquire_lock(redis, "lock:concert:343", 30)
