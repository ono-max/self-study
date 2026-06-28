require 'digest'

class ConsistentHash
    def initialize
        @ring = []
    end

    def hash(key)
        Digest::MD5.hexdigest(key).to_i(16)
    end

    def add_node(node_name, replicas = 100)
        replicas.times {|i|
            # [1, 5, 7, 8]
            # 0 => 0
            # 6 => 2
            # target < node.hash_val
            calculated_hash = hash("#{node_name}-#{i}")
            idx = 0
            @ring.each {|node|
                if calculated_hash < node[:hash_val]
                    break
                end
                idx += 1
            }
            @ring.insert(idx, {
                hash_val: calculated_hash,
                node: node_name
            })
        }
    end

    def get_node(key)
        calculated_hash = hash(key)
        idx = 0
        @ring.each{|node|
            if calculated_hash <= node[:hash_val]
                return node
            end
        }
        @ring.first
    end

    def remove_node(node_name)
        @ring.reject! {|node| node[:node] == node_name}
    end
end

node_2_counts = {}

initial_mapping = {}

ch = ConsistentHash.new
ch.add_node("Server A")
ch.add_node("Server B")
ch.add_node("Server C")

10000.times {|i|
    key = "user_#{i}"
    node_name = ch.get_node(key)[:node]
    initial_mapping[key] = node_name
}

ch.remove_node("Server B")

migrated_count = 0

10000.times {|i|
    key = "user_#{i}"
    node_name = ch.get_node(key)[:node]
    if initial_mapping[key] != node_name
        migrated_count += 1
    end
}

puts migrated_count

# Coding the Trade-off.

ch = ConsistentHash.new
ch.add_node("Server A")
ch.add_node("Server B")
ch.add_node("Server C")

unique_nodes = Set.new
100.times do |i|
    key = "user_1_#{i}"
    node_name = ch.get_node(key)[:node]
    unique_nodes.add(node_name)
end

puts unique_nodes.size

# Scaling Up!

ch = ConsistentHash.new
ch.add_node("Server A")
ch.add_node("Server B")
ch.add_node("Server C")

initial_mapping = {}

10000.times {|i|
    key = "user_#{i}"
    node_name = ch.get_node(key)[:node]
    initial_mapping[key] = node_name
}

ch.add_node("Server D")

original_node_2_count = {}

10000.times {|i|
    key = "user_#{i}"
    new_node_name = ch.get_node(key)[:node]
    original_node = initial_mapping[key]
    if original_node != new_node_name
        if original_node_2_count.key?(original_node)
            original_node_2_count[original_node] += 1
        else
            original_node_2_count[original_node] = 1
        end
    end
}
puts original_node_2_count
