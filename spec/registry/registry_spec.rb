require 'spec_helper'

RSpec.describe Registry do
  Person = Struct.new(:id, :name, :email)
  let(:u1) {
    Person.new(1, 'Dale', 'dale@twilightcoders.net')
  }

  let(:u2) {
    Person.new(2, 'Dale', 'dale@chillywinds.com')
  }

  let(:u3) {
    Person.new(3, 'Foo', 'foobar@twilightcoders.net')
  }

  let(:r1) {
    Registry.new([
      u1,
      u2
    ])
  }

  let(:r2) {
    Registry.new([
      u1,
      u2
    ])
  }

  it 'adds & deletes' do
    r1 << u3

    expect(r1.to_h).to eq({
      object_id: {
        u1.object_id => [u1],
        u2.object_id => [u2],
        u3.object_id => [u3]
      }
    })

    r1.delete(u2)

    expect(r1.to_h).to eq({
      object_id: {
        u1.object_id => [u1],
        u3.object_id => [u3]
      }
    })
  end

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

    expect(r2.find(:name, 'Bob')).to eq(d)
  end

  it 'unwatches' do
    r2.index(:name)

    d = r2[:name, 'Dale'].first

    expect(d.methods).to include(:__watched_name=, :__unwatched_name=)

    r2.delete(d)

    expect(d.methods).to_not include(:__watched_name=, :__unwatched_name=)

    d.name="Bob"
    expect(d.name).to eq("Bob")
  end

  context 'Access' do
    Vehicle = Struct.new(:id, :year, :type, :color)
    let(:v1) { Vehicle.new(1, 2000, 'car', 'blue') }
    let(:v2) { Vehicle.new(2, 2005, 'car', 'blue') }
    let(:v3) { Vehicle.new(3, 2005, 'car', 'red') }
    let(:v4) { Vehicle.new(4, 2005, 'truck', 'red') }
    let!(:registry) { Registry.new([v1, v2, v3, v4]) }
    context 'Access' do
      context 'with no index' do
        it 'should return 2 records' do
          vehicles = registry.where(type: 'car', color: 'blue')
          expect(vehicles.count).to eq(2)
        end

        it 'should return 3 records' do
          vehicles = registry.where(year: 2005)
          expect(vehicles.count).to eq(3)
        end
      end

      context 'with compound index' do
        before(:each) do
          registry.index([:type, :color])
        end

        it 'should return 2 records' do
          vehicles = registry.where(type: 'car', color: 'blue')
          expect(vehicles.count).to eq(2)
        end

        it 'should return 0 records' do
          vehicles = registry.where(type: 'motorcycle', color: 'yellow')
          expect(vehicles.count).to eq(0)
        end

        it 'should return 3 records' do
          vehicles = registry.where(type: 'car')
          expect(vehicles.count).to eq(3)
        end
      end
    end
  end

  context 'Compound Index' do
    Animal = Struct.new(:id, :name, :age)
    let(:a1) { Animal.new(1, "Corinthias", 10) }
    let(:a2) { Animal.new(2, "Gerry", 20) }
    let!(:registry) { Registry.new([a1, a2]) }

    it 'should create a compound index successfully' do
      expect{registry.index([:name, :age])}.to_not raise_error
    end

    it 'should ignore nil values as part of the index' do
      expect{registry.index([:name, :age, nil])}.to_not raise_error
    end
  end
end
