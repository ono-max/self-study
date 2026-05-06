class LeafNode
  attr_accessor :next_leaf
  attr_reader :keys

  def initialize
    @keys = []
    @values = []
    @next_leaf = nil
  end

  def insert(key, value)
    idx = @keys.index(key)
    if idx.nil?
      idx = 0
      # for loop @keys
      # Update the index until `key` becomes smaller than an element.
      # Once key is smaller than an element, exit the loop and plus 1.
      # Slide the key and value into their respective arrays.
      # For example, keys=[10, 20, 30] values = ['a', 'b', 'c']
      # 10 > 40 -> t: i = 0, idx = i + 1 = 1
      # 20 > 40 -> t: i = 1, idx = i + 1 = 2
      # 30 > 40 -> t: i = 2, idx = i + 1 = 3

      # 10 > 15 -> t: i = 0, idx = i + 1 = 1
      # 20 > 15 -> f: i = 1, idx = i + 1 = 2

      # 10 > 5
      @keys.each_with_index{|k, i|
        if k > key
          break
        end
        idx = i + 1
      }
      @keys.insert(idx, key)
      @values.insert(idx, value)
    else
      @values[idx] = value
    end
  end

  def promoted_key
    @keys.first
  end

  def split
    mid = @keys.size / 2
    right_node = self.class.new
    right_keys = @keys.pop(mid)
    right_vals = @values.pop(mid)
    right_keys.zip(right_vals) do |key, val|
      right_node.insert(key, val)
    end
    right_node.next_leaf = @next_leaf
    @next_leaf = right_node
    return [right_node.promoted_key, right_node]
  end
end

class InternalNode
  attr_accessor :keys, :children

  def initialize(max_capacity)
    @keys = []
    @children = []
    @max_capacity = max_capacity
  end

  def insert(key, value)
    # Routing the traffic
    # For loop @keys
    # Find the first bigger key from @keys.
    # Start the child index with 0.
    # [20, 40], 30
    # If 20 > 30 -> f
    # If 40 > 30 -> t: child_index = 1

    # [20, 40], 10
    # If 20 > 10 -> t: child_index = 0

    # [20, 40], 50
    # If 20 > 50 -> f
    # If 40 > 50 -> f
    # If 40 > 50 -> f: We need to handle this case!
    child_index = nil
    @keys.each_with_index do |k,i|
      if k > key
        child_index = i
        break
      end
    end
    if child_index == nil
      child_index = @keys.size
    end
    target = @children[child_index]
    target.insert(key, value)
    # Manage child split
    if target.keys.size > @max_capacity
     promoted_key, right_node = target.split()
     # [child#1, child#2, child#3] child#2 was promoted
     # child_index: 1, promoted_key: 30
     # [20, 40] -> expected_idx: 1, expected_node_idx: 2
     # [child#1, child#2, child#3] child#1 was promoted
     # child_index: 0, promoted_key: 10
     # [20, 40] -> expected_idx: 0, expected_node_idx: 1
     @keys.insert(child_index, promoted_key)
     @children.insert(child_index + 1, right_node)
    end
  end

  def split
    mid = @keys.size / 2
    right_node = self.class.new(@max_capacity)
    @keys.pop(mid - 1).each do |k|
      right_node.keys << k
    end
    @children.pop(mid).each do |c|
      right_node.children << c
    end
    [@keys.pop, right_node]
  end
end

class BPlusTree
  def initialize
    @max_capacity = 3
    @root = LeafNode.new()
  end

  def insert(key, value)
    @root.insert(key, value)
    if @root.keys.size > @max_capacity
      promoted_key, right_node = @root.split()
      node = InternalNode.new(@max_capacity)
      node.keys << promoted_key
      node.children << @root
      node.children << right_node
      @root = node
    end
  end
end
