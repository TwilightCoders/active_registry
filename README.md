[![Version      ](https://img.shields.io/gem/v/active_registry.svg?maxAge=2592000)](https://rubygems.org/gems/active_registry)
[![Build Status ](https://travis-ci.org/TwilightCoders/active_registry.svg)](https://travis-ci.org/TwilightCoders/active_registry)
[![Code Climate ](https://api.codeclimate.com/v1/badges/a18ae809af878357acfa/maintainability)](https://codeclimate.com/github/TwilightCoders/active_registry/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a18ae809af878357acfa/test_coverage)](https://codeclimate.com/github/TwilightCoders/active_registry/test_coverage)
[![Dependencies ](https://gemnasium.com/badges/github.com/TwilightCoders/active_registry.svg)](https://gemnasium.com/github.com/TwilightCoders/active_registry)

# ActiveRegistry

Provides a data structure for collecting homogeneous objects and indexing them for quick lookup.

## Requirements
Ruby 2.3+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_registry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_registry

## Usage

```ruby
  Person = Struct.new(:id, :name, :email)

  registry = ActiveRegistry.new([
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

Bug reports and pull requests are welcome on GitHub at https://github.com/TwilightCoders/active_registry. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
