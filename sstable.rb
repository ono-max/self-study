class SSTable
  def initialize(file_name)
    @index = {}
    @bloom_filters = BloomFilter.new(1000)
    # write-binary mode
    @file = File.open(file_name, 'wb')
  end

  def write_record(key, value)
    key_size = [key.bytesize].pack('L>')
    value_size = [value.bytesize].pack('L>')

    file_pos = @file.pos

    @file.write(key_size)
    @file.write(key)
    @file.write(value_size)
    @file.write(value)

    @bloom_filters.add(key)
    @index[key] = file_pos
  end

  def close
    file_pos = @file.pos
    Marshal.dump(@index, @file)
    bloom_file_pos = @file.pos
    Marshal.dump(@bloom_filters, @file)
    @file.write([file_pos, bloom_file_pos].pack('Q> Q>'))
    @file.close
  end
end

class SSTableReader
  def initialize(file_name)
    @file = File.open(file_name, 'rb')
    @file.seek(-16, IO::SEEK_END)
    index_offset, bloom_file_pos = @file.read(16).unpack('Q> Q>')
    @file.seek(bloom_file_pos, IO::SEEK_SET)
    @bloom_filters = Marshal.load(@file)
    @file.seek(index_offset, IO::SEEK_SET)
    @index = Marshal.load(@file)
  end

  def read_record(search_key)
    file_pos = @index[search_key]
    if file_pos == nil
      return nil
    end
    if !@bloom_filters.might_contain?(search_key)
      return nil
    end
    @file.seek(file_pos, IO::SEEK_SET)
    key_size = @file.read(4).unpack1('L>')
    key = @file.read(key_size)
    value_size = @file.read(4).unpack1('L>')
    value = @file.read(value_size)
    return value
  end

  def close
    @file.close
  end
end

class MemTable
  class Node
    attr_accessor :key, :value, :right, :left

    def initialize(key, value)
      @key = key
      @value = value
      @right = nil
      @left = nil
    end
  end
  def initialize
    @root = nil
  end

  def insert(key, value)
    if @root.nil?
      @root = Node.new(key, value)
    else
      insert_into_node(@root, key, value)
    end
  end

  def insert_into_node(current_node, key, value)
    if (key < current_node.key)
      if current_node.left.nil?
        current_node.left = Node.new(key, value)
      else
        insert_into_node(current_node.left, key, value)
      end
    end
    if (key == current_node.key)
      current_node.value = value
    end
    if (key > current_node.key)
      if current_node.right.nil?
        current_node.right = Node.new(key, value)
      else
        insert_into_node(current_node.right, key, value)
      end
    end
  end

  def each(&block)
    traverse_node(@root, &block)
  end

  def traverse_node(node, &block)
    return if node.nil?

    
    traverse_node(node.left, &block)
    
    block.call(node.key, node.value)

    traverse_node(node.right, &block)
  end
end

class BloomFilter
  def initialize(size)
    @size = size
    @bits = Array.new(size, false)
    @num_hashes = 3
  end

  def get_indexes(key)
    (1..@num_hashes).map do |i|
      (key + i.to_s).hash % @size
    end
  end

  def add(key)
    indexes = get_indexes(key)
    indexes.each do |i|
      @bits[i] = true
    end
  end

  def might_contain?(key)
    indexes = get_indexes(key)
    indexes.each do |i|
      if @bits[i] == false
        return false
      end
    end
    return true
  end
end

SSTableMetadata = Data.define(:file_name, :level, :min_key, :max_key) do
  def covers?(key)
    key >= min_key && key <= max_key
  end
end

class RAMTracker
  def initialize
    @levels = {
      0=>[],
      1=>[],
      2=>[]
    }
  end

  def add_file(file_name, level, min_key, max_key)
    file_meta = SSTableMetadata.new(file_name, level, min_key, max_key)
    @levels[level] << file_meta

    if level > 0
      @levels[level].sort_by! {|f| f.min_key }
    end
  end

  def find_files_to_search(search_key)
    candidate_files = []
    
    @levels[0].each{|meta|
      if meta.covers(search_key)
        candidate_files << meta.file_name
      end
    }

    (1..2).each{|level| 
      @levels[level].each {|meta|
        if meta.covers?(search_key)
          @candidate_files << meta.file_name
          break
        end
      }
    }

    return candidate_files

  end
end

# 1. The database is online! Users start writing data.
memtable = MemTable.new
memtable.insert("zebra", "stripes")
memtable.insert("apple", "red")
memtable.insert("mango", "sweet")
memtable.insert("banana", "yellow")
memtable.insert("apple", "green") # Overwriting an existing key

# 2. The MemTable hits its capacity. Time to flush to an SSTable!
writer = SSTable.new("data.sst")

# Because of your BST logic, this will naturally yield:
# apple, banana, mango, zebra
memtable.each do |key, value|
  writer.write_record(key, value)
end
writer.close

puts "SSTable successfully written to disk!"

# 3. The next day, a user wants to read from the database.
reader = SSTableReader.new("data.sst")

puts "Looking up 'apple': #{reader.read_record("apple").inspect}"   # => "green"
puts "Looking up 'zebra': #{reader.read_record("zebra").inspect}"   # => "stripes"
puts "Looking up 'ghost': #{reader.read_record("ghost").inspect}"   # => nil

reader.close