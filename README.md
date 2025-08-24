[![Version](https://img.shields.io/gem/v/registry.svg)](https://rubygems.org/gems/registry)
[![Build Status](https://github.com/TwilightCoders/registry/workflows/CI/badge.svg)](https://github.com/TwilightCoders/registry/actions)
[![Code Quality](https://img.shields.io/badge/qlty-monitored-blue)](https://qlty.sh)

# Registry

Provides a data structure for collecting homogeneous objects and indexing them for quick lookup.

## Requirements
Ruby 3.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'registry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install registry

## Usage

```ruby
  Person = Struct.new(:id, :name, :email)

  registry = Registry.new([
    Person.new(1, 'Dale', 'jason@twilightcoders.net'),
    Person.new(2, 'Dale', 'dale@twilightcoders.net')
  ])

  registry.index(:name)

  d = registry[:name, 'Dale'].first
  d.name = "Jason"

  registry.find(:name, 'Jason')
```

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `bundle exec rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TwilightCoders/registry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
