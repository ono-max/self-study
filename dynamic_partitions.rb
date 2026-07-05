MAX_PARTITION_SIZE = 10
NODE_COUNT = 3

partitions = [
    { min_key: 1, max_key: 100, node_index: 0, data: [] }
]

def insert_key(key, partitions)
    partitions.each do |partition|
        if partition[:min_key] <= key && key <= partition[:max_key]
            partition[:data] << key
            break
        end
    end
end

def check_and_split(partitions)
    new_partitions = []
    partitions.each do |partition|
        data = partition[:data]
        if data.size > MAX_PARTITION_SIZE
            half = data.size / 2
            sorted = data.sort
            first_half = sorted.take(half)
            second_half = sorted.drop(half)
            original_max = partition[:max_key]
            partition[:data] = first_half
            partition[:max_key] = first_half.last
            new_partitions << {
                min_key: first_half.last + 1,
                max_key: original_max,
                node_index: (partition[:node_index] + 1) % NODE_COUNT,
                data: second_half
            }
        end
    end
    partitions.concat(new_partitions)
end

# Let's insert 11 random keys
[14, 25, 2, 78, 41, 55, 95, 33, 62, 81, 90].each do |k|
  insert_key(k, partitions)
  check_and_split(partitions)
end
