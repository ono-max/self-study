# frozen_string_literal: true

# Example consumer that prints messages payloads
class ExampleConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      begin
        puts "Processing: [#{message.key}] #{message.raw_payload}"
        # Simulate a bug in our code!
        raise "Database timeout!" if message.raw_payload.include?("Penalty")
      rescue => e
        puts "Error processing message! Sending to DLQ."
        
        # 1. Route the failed message to our DLQ topic
        dlq_message = {
          topic: 'world-cup-dlq',
          payload: message.payload,
          key: message.key
        }

        Karafka.producer.produce_sync(**dlq_message)
      end
    end
  end

  # Run anything upon partition being revoked
  # def revoked
  # end

  # Define here any teardown things you want when Karafka server stops
  # def shutdown
  # end
end
