# frozen_string_literal: true

require 'set'

# Manages method watching for automatic reindexing when object attributes change
module RegistryMethodWatcher
  def initialize_method_watcher
    @watched_objects = Set.new
    @method_cache = {}
  end

  # Add an item to the watched objects set
  def add_to_watched_objects(item)
    @watched_objects.add(item)
  end

  # Remove an item from the watched objects set
  def remove_from_watched_objects(item)
    @watched_objects.delete(item)
  end

  # Set up watching on a setter method to trigger reindexing
  def watch_setter(item, idx)
    return if item.frozen?

    ensure_registry_reference(item)
    setter_method = lookup_setter_method(item.class, idx)
    return unless setter_method

    watched_method = :"__watched_#{setter_method}"
    return if item.methods.include?(watched_method)

    install_watched_method(item, idx, setter_method, watched_method)
  end

  # Remove watching from a setter method
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

  # Clean up all watched methods from all watched objects
  def cleanup_watched_methods
    @watched_objects.each do |item|
      indexes.each do |idx|
        ignore_setter(item, idx)
      end
    end
    @watched_objects.clear
  end

  # Full cleanup of watched methods and cache
  def cleanup!
    cleanup_watched_methods
  end

  private

  def lookup_setter_method(item_class, idx)
    cache_key = [item_class, idx]
    @method_cache[cache_key] ||= begin
      method_name = :"#{idx}="
      item_class.instance_methods.include?(method_name) ? method_name : nil
    end
  end

  def ensure_registry_reference(item)
    item.instance_variable_set(:@__registry__, self) unless item.instance_variable_defined?(:@__registry__)
  end

  def install_watched_method(item, idx, setter_method, watched_method)
    original_method = setter_method
    renamed_method = :"__unwatched_#{original_method}"

    item.singleton_class.class_eval do
      define_method(watched_method) do |*args|
        old_value = send(idx)
        send(renamed_method, *args).tap do |new_value|
          instance_variable_get(:@__registry__).send(:reindex_item, idx, self, old_value, new_value)
        end
      end
      alias_method renamed_method, original_method
      alias_method original_method, watched_method
    end
  end
end
