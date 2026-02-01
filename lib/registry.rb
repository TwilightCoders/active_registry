# frozen_string_literal: true
require_relative 'registry/version'

require 'set'
require_relative 'registry/index_store'
require_relative 'registry/query_cache'
require_relative 'registry/method_watcher'

class Registry < Set
  include RegistryIndexStore
  include RegistryQueryCache
  include RegistryMethodWatcher

  # Exception classes for better error handling
  class RegistryError < StandardError; end
  class MoreThanOneRecordFound < RegistryError; end
  class IndexNotFound < RegistryError; end
  class MissingAttributeError < RegistryError; end

  DEFAULT_INDEX = :object_id

  def initialize(*args, indexes: [], thread_safe: false)
    @thread_safe = thread_safe
    @mutex = Mutex.new if @thread_safe

    # Initialize module-specific state
    initialize_index_store
    initialize_query_cache
    initialize_method_watcher

    super(*args)
    reindex!(indexes)
  end

  def inspect
    to_a.inspect
  end

  def to_h
    @indexed
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
    remove_from_watched_objects(item)
    invalidate_cache
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
    add_to_watched_objects(item) unless include?(item)
    invalidate_cache
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
    with_thread_safety do
      cache_key = [:where, search_criteria.sort]
      cached_result = check_cache(cache_key)
      return new_registry_from_set(cached_result) if cached_result

      result_set = if search_criteria.size == 1
                     single_criteria_search(search_criteria)
                   else
                     multi_criteria_search(search_criteria)
                   end
      store_in_cache(cache_key, result_set)
      new_registry_from_set(result_set)
    end
  end

  # Check if any items exist matching the criteria
  def exists?(search_criteria)
    with_thread_safety do
      search_criteria.size == 1 ? single_criteria_exists?(search_criteria) : multi_criteria_exists?(search_criteria)
    end
  end

  def reindex!(new_indexes = [])
    cleanup_watched_methods # Clean up before reindexing
    @indexed = {}
    @indexes = []
    index(*([DEFAULT_INDEX] | new_indexes))
  end

  private

  def _find(search_criteria)
    results = where(search_criteria)
    yield if block_given? && results.count > 1
    results.first
  end

  def new_registry_from_set(set)
    Registry.new(set.to_a, indexes: indexes, thread_safe: @thread_safe)
  end

  def validate_index_exists!(idx)
    return if index_exists?(idx)

    raise IndexNotFound,
          "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. Add it with '.index(:#{idx})'"
  end

  def single_criteria_search(search_criteria)
    idx, value = search_criteria.first
    validate_index_exists!(idx)
    lookup_index(idx, value)
  end

  def multi_criteria_search(search_criteria)
    result_set = nil
    search_criteria.each do |idx, value|
      validate_index_exists!(idx)
      current_set = lookup_index(idx, value)
      result_set = result_set ? (result_set & current_set) : current_set
      break if result_set.empty?
    end
    result_set || Set.new
  end

  def single_criteria_exists?(search_criteria)
    idx, value = search_criteria.first
    validate_index_exists!(idx)
    lookup_index(idx, value).any?
  end

  def multi_criteria_exists?(search_criteria)
    result_set = nil
    search_criteria.each do |idx, value|
      validate_index_exists!(idx)
      current_set = lookup_index(idx, value)
      return false if current_set.nil? || current_set.empty?

      result_set = result_set ? (result_set & current_set) : current_set
      return false if result_set.empty?
    end
    true
  end

  # Thread safety wrapper
  def with_thread_safety(&block)
    if @thread_safe
      @mutex.synchronize(&block)
    else
      yield
    end
  end
end
