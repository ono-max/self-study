require 'zlib'

class BitCask
    def initialize(file_path)
        # The in-memory KeyDir: maps a String key to its physical location on disk
        @key_dir = {}
        # opens the file for reading and writing.
        # if it doesn't exist, it creates it.
        @active_file = File.open(file_path, 'a+b')
        # Force disk writes immediately, good for database logs
        @active_file.sync = true
        # If we are opening an existing file, start appending at the very end
        @current_offset = @active_file.size
        recover_key_dir
    end

    EntryLocation = Data.define(:file_id, :record_size, :record_offset, :timestamp)

    # key: String
    # value: String
    def put(key, value)
        timestamp = Time.now.to_i
        key_size = key.bytesize
        value_size = value.bytesize

        # 1. Prepare Metadata (Timestamp, Key Size, Value Size)
        # Q> = 8 bytes, L> = 4 bytes, L> = 4 bytes (Total 16 bytes)
        metadata = [timestamp, key_size, value_size].pack('Q> L> L>')

        # Calculate CRC32 of the metadata + key + value
        checksum = Zlib.crc32(metadata + key + value)

        # 2. Pack the header
        # We pack the checksum as 8 bytes (Q>) to match our 24-byte header design
        header = [checksum].pack('Q>') + metadata

        record_size = header.bytesize + key_size + value_size

        # 3. Write to Disk
        # Note: In 'a+' mode, Ruby will always append to the end anyway, 
        # but explicitly tracking @current_offset is required for our KeyDir!
        @active_file.write(header)
        @active_file.write(key)
        @active_file.write(value)

        # 4. Update KeyDir
        @key_dir[key] = EntryLocation.new(0, record_size, @current_offset, timestamp)

        # Advance the offset for the next write
        @current_offset+=record_size
    end

    def get(key)
        # 1. Look up the location in the in-memory KeyDir
        location = @key_dir[key]
        if location.nil?
            return nil
        end

        # 2. Jump to the exact offset on the disk
        @active_file.seek(location.record_offset)

        # 3. Read the Header
        header_data = @active_file.read(24) # 8 bytes for checksum + 16 bytes for metadata
        stored_crc, timestamp, key_size, value_size = header_data.unpack('Q> Q> L> l>')

        # 4. Read the Key and Value bytes
        key_data = @active_file.read(key_size)
        value_data = @active_file.read(value_size)

        # 5. Verify Data Integrity (The CRC Check)
        # We recreate the exact buffer

        metadata = [timestamp, key_size, value_size].pack('Q> L> l>')
        calculated_crc = Zlib.crc32(metadata + key_data + value_data)
        if calculated_crc != stored_crc
            raise "Data corruption detected for key: #{key}"
        end

        # 6. Success! Return the value as a String
        return value_data
    end

    def recover_key_dir
        read_offset = 0
        total_length = @active_file.size

        # Start reading from the very beginning of the file
        @active_file.seek(0)

        while read_offset < total_length
            # 1. Read the Header (24 bytes total)
            header_data = @active_file.read(24)
            _, timestamp, key_size, value_size = header_data.unpack('Q> Q> L> l>')

            # 2. Read the Key
            key_data = @active_file.read(key_size)

            # 3. Check for our foolproof Tombstone marker


            if value_size == TOMBSTONE_VALUE_SIZE
                @key_dir.delete(key_data)
                read_offset += 24 + key_size # Move past the header and key (no value
            else
                @active_file.seek(value_size, IO::SEEK_CUR) # Skip the value bytes for now
                # 4. Calculate total size and update the KeyDir
                record_size = 24 + key_size + value_size

                # If the key already exists in the map, this simply overwrites it
                # with the newest offset, handling updates perfectly!
                @key_dir[key_data] = EntryLocation.new(0, record_size, read_offset, timestamp)
                read_offset += record_size
            end
        end
        # Finally, ensure the engine knows exactly where to append the next new record
        @current_offset = read_offset
    end

    TOMBSTONE_VALUE_SIZE = -1

    def delete(key)
        unless @key_dir.key?(key)
            return
        end

        timestamp = Time.now.to_i
        key_size = key.bytesize
        value_size = TOMBSTONE_VALUE_SIZE

        # 1. Prepare Metadata (Timestamp, Key Size, Value Size)
        metadata = [timestamp, key_size, value_size].pack('Q> L> L>')

        # Calculate CRC32 of the metadata + key (no value bytes for tombstone)
        checksum = Zlib.crc32(metadata + key)

        # 2. Pack the header
        header = [checksum].pack('Q>') + metadata

        record_size = header.bytesize + key_size # No value bytes for tombstone

        @active_file.write(header)
        @active_file.write(key)
        
        @key_dir.delete(key)

        @current_offset += record_size
    end
end

# Assuming the BitCask class is defined above this line...

puts "--- 1. Initializing Database ---"
# Use a local file named 'toy_database.cask'
db_file = 'toy_database.cask'
File.delete(db_file) if File.exist?(db_file) # Start fresh for the test
db = BitCask.new(db_file)

puts "\n--- 2. Writing Data ---"
db.put('user_1', 'Alice')
db.put('user_2', 'Bob')
db.put('user_3', 'Charlie')
puts "Added Alice, Bob, and Charlie."

puts "\n--- 3. Reading Data ---"
puts "user_1 is: #{db.get('user_1')}"
puts "user_2 is: #{db.get('user_2')}"

puts "\n--- 4. Updating Data ---"
db.put('user_1', 'Alice Wonderland')
puts "Updated user_1. New value: #{db.get('user_1')}"

puts "\n--- 5. Deleting Data ---"
db.delete('user_2')
puts "Deleted user_2. Current value: #{db.get('user_2').inspect}"

puts "\n--- 6. Simulating a Database Restart ---"
# We destroy the old instance in memory and create a brand new one.
# This forces the engine to read the raw file and rebuild the KeyDir.
db = nil 
restarted_db = BitCask.new(db_file)

puts "Database restarted and KeyDir recovered!"
puts "user_1 (Updated)  : #{restarted_db.get('user_1')}"
puts "user_2 (Deleted)  : #{restarted_db.get('user_2').inspect}"
puts "user_3 (Untouched): #{restarted_db.get('user_3')}"

puts "\nTest completed successfully!"
