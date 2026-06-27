require 'waterdrop'

producer = WaterDrop::Producer.new
producer.setup do |config|
    config.kafka = { 'bootstrap.servers': 'localhost:9092' }
end

def broadcast_event(producer, match_id, event_message)
    # 2. Prepare the message hash. 
    # To guarantee ordering, we MUST tell Kafka to use the match_id as the partition key
    message = {
        topic: 'example',
        payload: event_message,
        # key: match_id
    }

    # 3. Send the message to the Kafka broker
    producer.produce_sync(message)
    puts "Broadcasted: [#{match_id}] #{event_message}"
end

# Simulating events for two simultaneous matches
broadcast_event(producer, "ARG-FRA", "Match Started!")
broadcast_event(producer, "BRA-GER", "Match Started!")
broadcast_event(producer, "ARG-FRA", "Goal by Messi!")
broadcast_event(producer, "ARG-FRA", "Penalty")


