class Car
    attr_reader :id, :color, :make
    def initialize(id, color, make)
        @id = id
        @color = color
        @make = make
    end
end

class LocalPartition
    def initialize
        @cars = []
        @color_index = {}
    end

    def insert(car)
        @cars << car
        if @color_index.key?(car.color)
            @color_index[car.color] << car
        else
            @color_index[car.color] = [car]
        end
    end

    def find_by_color(color)
        @color_index[color] || []
    end
end

class DocumentPartitionedDatabase
    def initialize(num_partitions)
        @partitions = Array.new(num_partitions) {LocalPartition.new}
    end

    def insert(car)
        partition_index = car.id % @partitions.size
        @partitions[partition_index].insert(car)
    end

    def find_by_color(color)
        cars = []
        @partitions.each do |partition|
            partition.find_by_color(color).each do |car|
                cars << car
            end
        end
        cars
    end
end

class TermPartitionedDatabase
    def initialize(num_partitions)
        @storage_partitions = Array.new(num_partitions) {Array.new}
        @index_partitions = Array.new(num_partitions) {Hash.new {|h, k| h[k] = []}}
    end

    def insert(car)
        index = car.id % @storage_partitions.size
        @storage_partitions[index] << car
        index = car.color.hash % @storage_partitions.size
        @index_partitions[index][car.color] << car.id
    end

    def find_by_color(color)
        index = color.hash % @storage_partitions.size
        ids = @index_partitions[index][color]
        cars = []
        ids.each do |id|
            index = id % @storage_partitions.size
            @storage_partitions[index].each do |car|
                if id == car.id
                    cars << car
                end
            end
        end
        cars
    end
end
