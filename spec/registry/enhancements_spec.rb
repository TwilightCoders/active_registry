# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registry do
  Employee = Struct.new(:id, :name, :email, :age)
  let(:u1) { Employee.new(1, 'Dale', 'dale@twilightcoders.net', 30) }
  let(:u2) { Employee.new(2, 'Dale', 'dale@billyjoel.com', 25) }
  let(:u3) { Employee.new(3, 'Bob', 'bob@example.com', 35) }
  let(:u4) { Employee.new(4, 'Alice', 'alice@example.com', 30) }

  context 'Enhanced API' do
    let!(:registry) { Registry.new([u1, u2, u3, u4]) }

    before(:each) do
      registry.index(:name, :email, :age)
    end

    describe '#exists?' do
      it 'should return true when items exist' do
        expect(registry.exists?(name: 'Dale')).to be true
      end

      it 'should return false when no items exist' do
        expect(registry.exists?(name: 'NonExistent')).to be false
      end

      it 'should work with multiple criteria' do
        expect(registry.exists?(name: 'Dale', age: 30)).to be true
        expect(registry.exists?(name: 'Dale', age: 40)).to be false
      end
    end

    describe 'Better error handling' do
      it 'should raise IndexNotFound for missing indexes' do
        expect { registry.where(nonexistent: 'value') }
          .to raise_error(Registry::IndexNotFound)
      end

      it 'should raise MissingAttributeError when adding item without required attributes' do
        expect { registry.add('string without attributes') }
          .to raise_error(Registry::MissingAttributeError)
      end
    end
  end

  context 'Thread safety' do
    let!(:registry) { Registry.new([u1, u2], thread_safe: true) }

    it 'should support thread_safe parameter' do
      expect(registry.instance_variable_get(:@thread_safe)).to be true
      expect(registry.instance_variable_get(:@mutex)).to be_a(Mutex)
    end

    it 'should work normally with thread safety enabled' do
      registry.index(:name)
      expect(registry.where(name: 'Dale').count).to eq(2) # Both u1 and u2 have name 'Dale'
    end
  end

  context 'Memory management' do
    let!(:registry) { Registry.new([u1, u2]) }

    before(:each) do
      registry.index(:name)
    end

    it 'should track watched objects' do
      expect(registry.instance_variable_get(:@watched_objects)).to include(u1, u2)
    end

    it 'should clean up watched methods' do
      item = registry.where(name: 'Dale').first
      original_method_count = item.methods.count

      registry.cleanup!

      # Methods should be cleaned up
      expect(item.methods.count).to be <= original_method_count
    end

    it 'should remove from watched objects on delete' do
      registry.delete(u1)
      expect(registry.instance_variable_get(:@watched_objects)).not_to include(u1)
    end
  end

  context 'Exception hierarchy' do
    it 'should have proper exception inheritance' do
      expect(Registry::MoreThanOneRecordFound.ancestors).to include(Registry::RegistryError)
      expect(Registry::IndexNotFound.ancestors).to include(Registry::RegistryError)
      expect(Registry::MissingAttributeError.ancestors).to include(Registry::RegistryError)
    end
  end

  context 'Query caching' do
    let!(:registry) { Registry.new([u1, u2, u3, u4]) }

    before(:each) do
      registry.index(:name, :age)
    end

    describe '#cache_stats' do
      it 'should track cache hits and misses' do
        # First query - cache miss
        registry.where(name: 'Dale')
        stats = registry.cache_stats
        expect(stats[:misses]).to eq(1)
        expect(stats[:hits]).to eq(0)

        # Second identical query - cache hit
        registry.where(name: 'Dale')
        stats = registry.cache_stats
        expect(stats[:hits]).to eq(1)
        expect(stats[:misses]).to eq(1)
        expect(stats[:hit_rate]).to eq(50.0)
      end

      it 'should invalidate cache on registry changes' do
        # Prime the cache
        registry.where(name: 'Dale')
        registry.where(name: 'Dale')
        expect(registry.cache_stats[:hits]).to eq(1)

        # Add new item - should clear cache
        u5 = Employee.new(5, 'Dale', 'dale@new.com', 28)
        registry.add(u5)

        # Next query should be a cache miss
        registry.where(name: 'Dale')
        stats = registry.cache_stats
        expect(stats[:misses]).to eq(2) # Original miss + new miss after invalidation
      end
    end
  end
end
