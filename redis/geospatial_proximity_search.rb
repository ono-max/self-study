require 'redis'

def add_driver_location(redis, driver_id, longitude, latitude)
    # 1. Add the driver to the 'drivers' geospatial index
    redis.geoadd("drivers", longitude, latitude, driver_id)
  
    puts "Added #{driver_id} to the map!"
end

redis = Redis.new

# Let's add some drivers in Tokyo! 🗼
add_driver_location(redis, "driver_mario", 139.7670, 35.6812)
add_driver_location(redis, "driver_luigi", 139.7700, 35.6850)