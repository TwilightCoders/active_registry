class Record
  attr_reader :item

  def initialize(item)
    @item = item
    @index_membership = []
  end

  def add_index(idx)
    @index_membership.push(idx)
  end
end
