class Registry < Set

  VERSION = "0.1.0"

  DEFAULT_INDEX = :object_id

  def initialize(*args)
    @indexed = {}
    super
    index(DEFAULT_INDEX)
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

  def find(search_criteria)
    sets = []
    search_criteria.each do |idx, value|
      raise "No '#{idx}' index! Add it with '.index(:#{idx})'" unless @indexed.include?(idx)
      set = @indexed.dig(idx, value) || Set.new
      sets.push(set)
    end

    subset_elements  = sets.reduce(sets.first, &:&)
    subset_registry  = Registry.new(subset_elements)
    existing_indexes = @indexed.keys
    existing_indexes.delete(:object_id)
    existing_indexes.each { |existing_index| subset_registry.index(existing_index) }
    subset_registry
  end

  def index(*indexes)
    indexes.each do |idx|
      warn "Index #{idx} already exists!" and next if @indexed.key?(idx)
      each { |item| watch_setter(item, idx) }
      indexed_elements = group_by { |a| a.send(idx) }
      indexed_sets = Hash[indexed_elements.keys.zip(indexed_elements.values.map { |e| Set.new(e) })]
      @indexed[idx] = indexed_sets
    end
  end

  def reindex!(indexes = [])
    (indexes = @indexed.keys & [indexes].flatten).any? || indexes = @indexed.keys
    @indexed = {}
    index(DEFAULT_INDEX)
    index(*indexes)
  end

  protected
def reindex(idx, item, old_value, new_value)
    if (new_value != old_value)
      @indexed[idx][old_value].delete item
      (@indexed[idx][new_value] ||= Set.new).add item
    end
  end

  private

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
