require 'spec_helper'

RSpec.describe Registry do
  Person = Struct.new(:id, :name, :email)
  let(:u1) { Person.new(1, 'Dale', 'dale@twilightcoders.net') }
  let(:u2) { Person.new(2, 'Dale', 'dale@chillywinds.com') }
  let(:u3) { Person.new(3, 'Foo', 'foobar@twilightcoders.net') }

  context 'Adding' do
    let!(:r1) { Registry.new([ u1, u2 ]) }

    it 'should add the correct item' do
      r1 << u3

      expect(r1).to contain_mappings(
        object_id: {
          u1.object_id => [u1],
          u2.object_id => [u2],
          u3.object_id => [u3]
        }
      )
    end
  end

  context 'Deleting' do
    let!(:r1) { Registry.new([ u1, u2 ]) }

    before(:each) do
      r1 << u3
    end

    it 'should remove the correct item' do
      r1.delete(u2)

      expect(r1).to contain_mappings(
        object_id: {
          u1.object_id => [u1],
          u3.object_id => [u3]
        }
      )
    end
  end

  context "Access" do
    let!(:registry) { Registry.new([u1, u2, u3]) }

    before(:each) do
      registry.index(:name, :email)
    end

    it 'should return a registry' do
      subregistry = registry.find(name: 'Dale')
      expect(subregistry).to be_a_kind_of(Registry)
    end

    it 'should be able to access with the subregistry' do
      subregistry = registry.find(name: 'Dale')
      item = subregistry.find(email: 'dale@chillywinds.com')
      expect(item.first).to eq(u2)
    end

    it 'should be able to access with the subregistry' do
      subregistry = registry.find(name: 'Dale', email: 'dale@chillywinds.com')
      expect(subregistry.first).to eq(u2)
    end

    it 'should be able to access with the subregistry' do
      subregistry = registry.find(name: 'Dale', email: 'snail@chillywinds.com')
      expect(subregistry.count).to eq(0)
    end
  end

  context "Indexing" do
    let!(:registry) { Registry.new([ u1, u2 ]) }

    it 'indexes' do
      registry.index(:name)

      expect(registry).to contain_mappings(
        object_id: {
          u1.object_id => [u1],
          u2.object_id => [u2]
        },
        name: {
          "Dale" => [u1, u2]
        }
      )
    end

    it 'reindexes' do
      registry.index(:name)

      d = registry.find(name: 'Dale').first
      d.name = "Bob"

      expect(registry.find(name: 'Bob').first).to eq(d)
    end
  end

  context 'watches' do
    Animal = Struct.new(:id, :name)
    let!(:a1) { Animal.new(1, 'Boris') }
    let!(:a1_original_methods) { a1.methods }
    let!(:a1_original_method_count) { a1.methods.count }
    let!(:registry) { Registry.new([ a1 ]) }

    before(:each) do
      registry.index(:name)
    end

    it 'should add only two methods' do
      d = registry.find(name: 'Boris').first
      expect(d.methods.count).to eq(a1_original_method_count + 2)
    end

    it 'should include expected methods' do
      d = registry.find(name: 'Boris').first
      expect(d.methods).to include(:__watched_name=, :__unwatched_name=)
    end
  end

  context 'unwatches' do
    let!(:registry) { Registry.new([ u1, u2 ]) }

    before(:each) do
      registry.index(:name)
    end

    it 'should not include expected methods' do
      d = registry.find(name: 'Dale').first
      registry.delete(d)

      expect(d.methods).to_not include(:__watched_name=, :__unwatched_name=)
    end

    it 'should set the name after removing an element from the registry' do
      d = registry.find(name: 'Dale').first
      registry.delete(d)

      d.name="Bob"
      expect(d.name).to eq("Bob")
    end
  end
end
