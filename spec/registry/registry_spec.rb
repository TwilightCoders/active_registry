require 'spec_helper'

RSpec.describe Registry do
  Person = Struct.new(:id, :name, :email)
  let(:u1) { Person.new(1, 'Dale', 'dale@twilightcoders.net') }
  let(:u2) { Person.new(2, 'Dale', 'dale@chillywinds.com') }
  let(:u3) { Person.new(3, 'Foo', 'foobar@twilightcoders.net') }

  context 'Adding' do
    let(:r1) { Registry.new([ u1, u2 ]) }

    it 'should add the correct item' do
      r1 << u3

      expect(r1.to_h).to eq({
        object_id: {
          u1.object_id => [u1],
          u2.object_id => [u2],
          u3.object_id => [u3]
        }
      })
    end
  end

  context 'Deleting' do
    let(:r1) { Registry.new([ u1, u2 ]) }

    before(:each) do
      r1 << u3
    end

    it 'should remove the correct item' do
      r1.delete(u2)

      expect(r1.to_h).to eq({
        object_id: {
          u1.object_id => [u1],
          u3.object_id => [u3]
        }
      })
    end
  end

  context "Indexing" do
    let(:r2) { Registry.new([ u1, u2 ]) }

    it 'indexes' do
      r2.index(:name)

      expect(r2.to_h).to eq({
        object_id: {
          u1.object_id => [u1],
          u2.object_id => [u2]
        },
        name: {
          "Dale" => [
            u1, u2
          ]
        }
      })
    end

    it 'reindexes' do
      r2.index(:name)

      d = r2[:name, 'Dale'].first
      d.name = "Bob"

      expect(r2[:name, 'Bob'].first).to eq(d)
    end

    context 'unwatches' do
      before(:each) do
        r2.index(:name)
      end

      it 'should include expected methods' do
        d = r2[:name, 'Dale'].first

        expect(d.methods).to include(:__watched_name=, :__unwatched_name=)
      end

      it 'should not include expected methods' do
        d = r2[:name, 'Dale'].first
        r2.delete(d)

        expect(d.methods).to_not include(:__watched_name=, :__unwatched_name=)
      end

      it 'should set the name after removing an element from the registry' do
        d = r2[:name, 'Dale'].first
        r2.delete(d)

        d.name="Bob"
        expect(d.name).to eq("Bob")
      end
    end
  end
end
