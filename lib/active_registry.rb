class ActiveRegistry < Set
  class MoreThanOneRecordFound < StandardError
  end

  VERSION = "0.1.0"

  DEFAULT_INDEX = :object_id

  def initialize(*args, indexes: [])
    @indexed = {}
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
      rescue NoMethodError => e
        raise "#{item.name} cannot be added because indexable attribute (#{idx}) is missing."
      end
    end
    super(item)
  end

  def add(item)
    @indexed.each do |idx, store|
      watch_setter(item, idx) unless include?(item)
      begin
        idx_value = item.send(idx)
        (store[idx_value] ||= Set.new) << (item)
      rescue NoMethodError => e
        raise "#{item.name} cannot be added because indexable attribute (#{idx}) is missing."
      end
    end
    super(item)
  end
  alias << add

  def find!(search_criteria)
    _find(search_criteria) { raise MoreThanOneRecordFound, "There were more than 1 records found" }
  end

  def find(search_criteria)
    _find(search_criteria) { warn "There were more than 1 records found" }
  end

  def where(search_criteria)
    sets = search_criteria.inject([]) do |sets, (idx, value)|
      raise "No '#{idx}' index! Add it with '.index(:#{idx})'" unless @indexed.include?(idx)
      sets << (@indexed.dig(idx, value) || Set.new)
    end

    subset_records = sets.reduce(sets.first, &:&)
    subset_registry = ActiveRegistry.new(subset_records, indexes: indexes)
    subset_registry
  end

  def index(*indexes)
    indexes.each do |idx|
      warn "Index #{idx} already exists!" and next if @indexed.key?(idx)
      each { |item| watch_setter(item, idx) }
      indexed_records = group_by { |a| a.send(idx) }
      indexed_sets = Hash[indexed_records.keys.zip(indexed_records.values.map { |e| Set.new(e) })]
      @indexed[idx] = indexed_sets
    end
  end

  def reindex!(indexes = [])
    @indexed = {}
    index(*([DEFAULT_INDEX] | indexes))
  end

  protected

  def reindex(idx, item, old_value, new_value)
    if (new_value != old_value)
      @indexed[idx][old_value].delete item
      (@indexed[idx][new_value] ||= Set.new).add item
    end
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
      watched_method = "__watched_#{original_method}".to_sym
      renamed_method = "__unwatched_#{original_method}".to_sym
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
      watched_method = "__watched_#{original_method}".to_sym
      renamed_method = "__unwatched_#{original_method}".to_sym
      next unless item.methods.include?(watched_method)
      item.singleton_class.class_eval do
        alias_method original_method, renamed_method
        remove_method(watched_method)
        remove_method(renamed_method)
      end
    end
  end

end
