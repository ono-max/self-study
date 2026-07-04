partitions = []
node_count = 10

1000.times do |partition|
    partitions << {
        partition_index: partition,
        node_index: partition % node_count
    }
end

def assign_node(key, partitions)
  idx = key % partitions.size
  partitions[idx][:node_index]
end

keys = (1..100).to_a

initial_placement = {}
keys.each do |key|
  initial_placement[key] = assign_node(key, partitions)
end

moved_keys_count = 0

new_node_count = 11

stolen = partitions.size / new_node_count

partitions.sample(stolen).each do |partition|
    partition[:node_index] = 10
end

second_placement = {}
keys.each do |key|
  second_placement[key] = assign_node(key, partitions)
end

second_placement.each do |key, val|
    if val != initial_placement[key]
        moved_keys_count += 1
    end
end

puts moved_keys_count
