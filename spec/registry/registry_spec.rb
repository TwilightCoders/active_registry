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

end
