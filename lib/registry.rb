# frozen_string_literal: true
require_relative 'registry/version'

require 'set'

class Registry < Set
  # Exception classes for better error handling
  class RegistryError < StandardError; end
  class MoreThanOneRecordFound < RegistryError; end
  class IndexNotFound < RegistryError; end
  class MissingAttributeError < RegistryError; end

  DEFAULT_INDEX = :object_id

  def initialize(*args, indexes: [], thread_safe: false)
    @indexed = {}
    @thread_safe = thread_safe
    @mutex = Mutex.new if @thread_safe
    @watched_objects = Set.new # Track objects with watched methods for cleanup
    @method_cache = {} # Cache setter method lookups
    @batch_mode = false # For optimizing bulk operations
    @query_cache = {} # Cache frequent query results
    @cache_hits = 0 # Performance tracking
    @cache_misses = 0
    super(*args)
    reindex!(indexes)
  end

  def inspect
    to_a.inspect
  end

  def to_h
    @indexed
  end

  def indexes
    @indexed.keys - [:object_id]
  end

  def delete(item)
    @indexed.each do |idx, store|
      ignore_setter(item, idx) if include?(item)
      begin
        idx_value = item.send(idx)
        (store[idx_value] ||= Set.new).delete(item)
        store.delete(idx_value) if store[idx_value].empty?
      rescue NoMethodError
        raise MissingAttributeError,
              "Item #{item.inspect} cannot be deleted because indexable attribute '#{idx}' " \
              'is missing or not accessible.'
      end
    end
    @watched_objects.delete(item)
    # Invalidate query cache when registry changes
    @query_cache.clear
    super
  end

  def add(item)
    @indexed.each do |idx, store|
      watch_setter(item, idx) unless include?(item)
      begin
        idx_value = item.send(idx)
        (store[idx_value] ||= Set.new) << item
      rescue NoMethodError
        raise MissingAttributeError,
              "Item #{item.inspect} cannot be added because indexable attribute '#{idx}' is missing or not accessible."
      end
    end
    @watched_objects.add(item) unless include?(item)
    # Invalidate query cache when registry changes
    @query_cache.clear
    super
  end
  alias << add

  def find!(search_criteria)
    _find(search_criteria) { raise MoreThanOneRecordFound, 'There were more than 1 records found' }
  end

  def find(search_criteria)
    _find(search_criteria) { warn 'There were more than 1 records found' }
  end

  def where(search_criteria)
    # Check cache first for frequent queries
    cache_key = [:where, search_criteria.sort]
    if @query_cache.key?(cache_key)
      @cache_hits += 1
      cached_items = @query_cache[cache_key]
      return Registry.new(cached_items.to_a, indexes: indexes, thread_safe: @thread_safe)
    end
    @cache_misses += 1

    # Fast path for single criteria - avoid array creation and reduce operations
    if search_criteria.size == 1
      idx, value = search_criteria.first
      unless @indexed.include?(idx)
        raise IndexNotFound,
              "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. Add it with '.index(:#{idx})'"
      end
      
      result_set = @indexed.dig(idx, value) || Set.new
      # Cache the result set for future queries
      @query_cache[cache_key] = result_set.dup
      return Registry.new(result_set.to_a, indexes: indexes, thread_safe: @thread_safe)
    end

    # Multi-criteria path - optimize intersection logic
    result_set = nil
    search_criteria.each do |idx, value|
      unless @indexed.include?(idx)
        raise IndexNotFound,
              "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. Add it with '.index(:#{idx})'"
      end

      current_set = @indexed.dig(idx, value) || Set.new
      result_set = result_set ? (result_set & current_set) : current_set
      
      # Early exit if no intersection possible
      break if result_set.empty?
    end

    final_result = result_set || Set.new
    # Cache the result set for future queries (limit cache size)
    if @query_cache.size < 1000
      @query_cache[cache_key] = final_result.dup
    end
    
    Registry.new(final_result.to_a, indexes: indexes, thread_safe: @thread_safe)
  end

  # Check if any items exist matching the criteria
  def exists?(search_criteria)
    with_thread_safety do
      # Fast path for single criteria
      if search_criteria.size == 1
        idx, value = search_criteria.first
        raise IndexNotFound, 
              "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. " \
              "Add it with '.index(:#{idx})'" unless @indexed.include?(idx)
        
        return @indexed.dig(idx, value)&.any? || false
      end
      
      # Multi-criteria path with intersection logic
      result_set = nil
      search_criteria.each do |idx, value|
        raise IndexNotFound, 
              "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. " \
              "Add it with '.index(:#{idx})'" unless @indexed.include?(idx)

        current_set = @indexed.dig(idx, value)
        return false if current_set.nil? || current_set.empty?
        
        result_set = result_set ? (result_set & current_set) : current_set
        return false if result_set.empty?
      end
      
      true
    end
  end

  def index(*indexes)
    indexes.each do |idx|
      warn "Index #{idx} already exists!" and next if @indexed.key?(idx)

      # Optimize: Build index hash directly instead of using group_by + transformation
      index_hash = {}
      each do |item|
        watch_setter(item, idx)
        @watched_objects.add(item) # Track watched objects
        
        # Get the index value and build the index in one pass
        begin
          idx_value = item.send(idx)
          (index_hash[idx_value] ||= Set.new) << item
        rescue NoMethodError
          raise MissingAttributeError,
                "Item #{item.inspect} cannot be indexed because attribute '#{idx}' is missing or not accessible."
        end
      end
      @indexed[idx] = index_hash
    end
  end

  def reindex!(indexes = [])
    cleanup_watched_methods # Clean up before reindexing
    @indexed = {}
    index(*([DEFAULT_INDEX] | indexes))
  end

  # Clean up method watching for memory management
  def cleanup_watched_methods
    @watched_objects.each do |item|
      @indexed.each_key { |idx| ignore_setter(item, idx) }
    end
    @watched_objects.clear
  end

  # Manual cleanup method for long-lived registries
  def cleanup!
    cleanup_watched_methods
  end

  # Cache statistics for performance monitoring
  def cache_stats
    total_queries = @cache_hits + @cache_misses
    return { hits: 0, misses: 0, hit_rate: 0.0, total_queries: 0 } if total_queries == 0
    
    {
      hits: @cache_hits,
      misses: @cache_misses,
      hit_rate: (@cache_hits.to_f / total_queries * 100).round(2),
      total_queries: total_queries
    }
  end

  protected

  def reindex(idx, item, old_value, new_value)
    return unless new_value != old_value

    @indexed[idx][old_value].delete item
    (@indexed[idx][new_value] ||= Set.new).add item
    # Invalidate query cache when items change
    @query_cache.clear
  end

  private

  def _find(search_criteria)
    results = where(search_criteria)
    yield if block_given? && results.count > 1
    results.first
  end

  def watch_setter(item, idx)
    return if item.frozen?

    # Use cached method lookup
    item_class = item.class
    cache_key = [item_class, idx]
    
    setter_method = @method_cache[cache_key] ||= begin
      method_name = :"#{idx}="
      item_class.instance_methods.include?(method_name) ? method_name : nil
    end
    
    return unless setter_method
    
    watched_method = :"__watched_#{setter_method}"
    return if item.methods.include?(watched_method)

    # Optimize: Reduce closure overhead by storing registry reference directly on item
    item.instance_variable_set(:@__registry__, self) unless item.instance_variable_defined?(:@__registry__)
    original_method = setter_method
    renamed_method = :"__unwatched_#{original_method}"

    item.singleton_class.class_eval do
      define_method(watched_method) do |*args|
        old_value = send(idx) # Use direct send instead of item.send
        send(renamed_method, *args).tap do |new_value|
          instance_variable_get(:@__registry__).send(:reindex, idx, self, old_value, new_value)
        end
      end
      alias_method renamed_method, original_method
      alias_method original_method, watched_method
    end
  end

  def ignore_setter(item, idx)
    return if item.frozen?

    # Use cached method lookup
    item_class = item.class
    cache_key = [item_class, idx]
    setter_method = @method_cache[cache_key]
    
    return unless setter_method

    original_method = setter_method
    watched_method = :"__watched_#{original_method}"
    renamed_method = :"__unwatched_#{original_method}"
    
    return unless item.methods.include?(watched_method)

    item.singleton_class.class_eval do
      alias_method original_method, renamed_method
      remove_method(watched_method)
      remove_method(renamed_method)
    end
  end

  # Thread safety wrapper
  def with_thread_safety
    if @thread_safe
      @mutex.synchronize { yield }
    else
      yield
    end
  end
end
