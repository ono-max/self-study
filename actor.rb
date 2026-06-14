require 'thread'

class Actor
    def initialize
        @queue = Queue.new
        @thread = Thread.start do
            while message = @queue.pop
                receive(message)
            end
        end
    end

    def receive(message)
        raise NotImplementedError, "Subclasses must implement the receive method"
    end

    def async_send(message)
        @queue << message
    end
end

class CounterActor < Actor
    def initialize
        super
        @count = 0
    end

    def receive(message)
        case message
        when :increment
            @count += 1
            puts "Count is now: #{@count}"
        else
            puts "Ignored unknown message: #{message}"
        end
    end
end

actor = CounterActor.new

threads = []
5.times do
    threads << Thread.start do
        100.times do
            actor.async_send(:increment)
        end
    end
end

threads.each do |t|
    t.join
end

sleep 0.5
