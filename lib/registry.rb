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
    sets = search_criteria.inject([]) do |sets, (idx, value)|
      unless @indexed.include?(idx)
        raise IndexNotFound,
              "Index '#{idx}' not found. Available indexes: #{indexes.inspect}. Add it with '.index(:#{idx})'"
      end

      sets << (@indexed.dig(idx, value) || Set.new)
    end

    subset_records = sets.reduce(sets.first, &:&) || Set.new
    Registry.new(subset_records.to_a, indexes: indexes, thread_safe: @thread_safe)
  end

  # Check if any items exist matching the criteria
  def exists?(search_criteria)
    !where(search_criteria).empty?
  end

  def index(*indexes)
    indexes.each do |idx|
      warn "Index #{idx} already exists!" and next if @indexed.key?(idx)

      each do |item|
        watch_setter(item, idx)
        @watched_objects.add(item) # Track watched objects
      end
      indexed_records = group_by { |a| a.send(idx) }
      indexed_sets = indexed_records.keys.zip(indexed_records.values.map { |e| Set.new(e) }).to_h
      @indexed[idx] = indexed_sets
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

  protected

  def reindex(idx, item, old_value, new_value)
    return unless new_value != old_value

    @indexed[idx][old_value].delete item
    (@indexed[idx][new_value] ||= Set.new).add item
  end

  private

  def _find(search_criteria)
    results = where(search_criteria)
    yield if block_given? && results.count > 1
    results.first
  end

  def watch_setter(item, idx)
    return if item.frozen?

    __registry__ = self
    item.public_methods.select { |m| m.match(/^#{idx}=$/) }.each do |original_method|
      watched_method = :"__watched_#{original_method}"
      renamed_method = :"__unwatched_#{original_method}"
      next if item.methods.include?(watched_method)

      item.singleton_class.class_eval do
        define_method(watched_method) do |*args|
          old_value = item.send(idx)
          send(renamed_method, *args).tap do |new_value|
            __registry__.send(:reindex, idx, item, old_value, new_value)
          end
        end
        alias_method renamed_method, original_method
        alias_method original_method, watched_method
      end
    end
  end

  def ignore_setter(item, idx)
    return if item.frozen?

    item.public_methods.select { |m| m.match(/^#{idx}=$/) }.each do |original_method|
      watched_method = :"__watched_#{original_method}"
      renamed_method = :"__unwatched_#{original_method}"
      next unless item.methods.include?(watched_method)

      item.singleton_class.class_eval do
        alias_method original_method, renamed_method
        remove_method(watched_method)
        remove_method(renamed_method)
      end
    end
  end
end
