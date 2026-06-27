require 'zlib'

class ToyPartition
    def initialize
        @log = []
    end

    def append(message)
        offset = @log.size
        @log << message
        offset
    end

    def read_at(offset)
        @log[offset]
    end
end

class ToyBroker
    def initialize
        @topics = {}
    end

    def create_topic(name, num_partitions)
        @topics[name] = Array.new(num_partitions) { ToyPartition.new }
    end


    def produce(topic_name, key, message)
        partitions = @topics[topic_name]
        raise "Topic does not exist!" if partitions.nil?

        # 1. Calculate the partition index using the key
        idx = Zlib.crc32(key) % partitions.size

        # 2. Grab that specific ToyPartition object from the `partitions` array
        partition = partitions[idx]

        # 3. Append the message to it and return the offset
        partition.append(message)
    end

    def fetch(topic_name, partition_index, offset)
        partitions = @topics[topic_name]
        return nil if partitions.nil? || partitions[partition_index].nil?

        partitions[partition_index].read_at(offset)
    end
end

class ToyConsumer
    def initialize(broker, topic_name, partition_index)
        @broker = broker
        @topic_name = topic_name
        @partition_index = partition_index
        @current_offset = 0
    end

    def consume
        message = @broker.fetch(@topic_name, @partition_index, @current_offset)

        if message
            puts message
            @current_offset += 1
        end
    end
end

# --- Let's run our Toy Kafka! ---
broker = ToyBroker.new
broker.create_topic("world-cup", 3)

# Produce some events using match IDs as keys
broker.produce("world-cup", "ARG-FRA", "Match Started: ARG vs FRA")
broker.produce("world-cup", "BRA-GER", "Match Started: BRA vs GER")
broker.produce("world-cup", "ARG-FRA", "Goal by Messi!")
broker.produce("world-cup", "ARG-FRA", "Yellow Card for Mbappe")

# Set up consumers for our partitions
consumer_0 = ToyConsumer.new(broker, "world-cup", 0)
consumer_1 = ToyConsumer.new(broker, "world-cup", 1)
consumer_2 = ToyConsumer.new(broker, "world-cup", 2)

puts "\n--- Consuming Messages ---"
# Let's have all consumers try to pull data 3 times
3.times do
  consumer_0.consume
  consumer_1.consume
  consumer_2.consume
end
