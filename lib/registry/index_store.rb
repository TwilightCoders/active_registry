# frozen_string_literal: true

require 'set'

# Manages index storage and reindexing operations
module RegistryIndexStore
  attr_reader :indexes

  def initialize_index_store
    @indexed = {}
    @indexes = []
  end

  # Add one or more indexes to the registry
  def index(*new_indexes)
    new_indexes.each do |idx|
      warn "Index #{idx} already exists!" and next if @indexed.key?(idx)

      # OPTIMIZE: Build index hash directly instead of using group_by + transformation
      index_hash = {}
      each do |item|
        watch_setter(item, idx)
        add_to_watched_objects(item) # Track watched objects

        # Get the index value and build the index in one pass
        idx_value = item.send(idx)
        (index_hash[idx_value] ||= Set.new) << item
      end
      @indexed[idx] = index_hash
      @indexes << idx
    end
  end

  # Rebuild all indexes from scratch
  def reindex!(new_indexes = [])
    @indexed.clear
    @indexes.clear
    index(*new_indexes)
  end

  # Update an index when an item's value changes
  def reindex_item(idx, item, old_value, new_value)
    return unless @indexed.key?(idx)

    @indexed[idx][old_value].delete item
    (@indexed[idx][new_value] ||= Set.new).add item
  end

  # Look up items by index value
  def lookup_index(idx, value)
    @indexed.dig(idx, value) || Set.new
  end

  # Check if an index exists
  def index_exists?(idx)
    @indexed.key?(idx)
  end
end
