# Registry

[![Version](https://img.shields.io/gem/v/registry.svg)](https://rubygems.org/gems/registry)
[![CI](https://github.com/TwilightCoders/active_registry/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/TwilightCoders/active_registry/actions/workflows/ci.yml)
[![Code Coverage](https://qlty.sh/gh/TwilightCoders/projects/active_registry/coverage.svg)](https://qlty.sh/gh/TwilightCoders/projects/active_registry)
[![Maintainability](https://qlty.sh/gh/TwilightCoders/projects/active_registry/maintainability.svg)](https://qlty.sh/gh/TwilightCoders/projects/active_registry)

Provides a data structure for collecting homogeneous objects and indexing them for quick lookup.

## Requirements

Ruby 3.0+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'registry'
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install registry
```

## Usage

### Basic Usage

```ruby
Person = Struct.new(:id, :name, :email)

registry = Registry.new([
  Person.new(1, 'Dale', 'jason@twilightcoders.net'),
  Person.new(2, 'Dale', 'dale@twilightcoders.net')
])

registry.index(:name)

# Find items using where method
results = registry.where(name: 'Dale')

# Check if items exist
registry.exists?(name: 'Dale') #=> true

# Automatic reindexing when attributes change
d = registry.where(name: 'Dale').first
d.name = "Jason"
registry.where(name: 'Jason') # Contains the updated item
```

### Advanced Features

#### Thread Safety

```ruby
# Create a thread-safe registry
registry = Registry.new(items, thread_safe: true)
```

#### Memory Management

```ruby
# Clean up method watching for long-lived registries
registry.cleanup!
```

#### Error Handling

```ruby
begin
  registry.where(nonexistent_index: 'value')
rescue Registry::IndexNotFound => e
  puts "Index not found: #{e.message}"
end

begin
  registry.add("invalid item")
rescue Registry::MissingAttributeError => e
  puts "Missing required attributes: #{e.message}"
end
```

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `bundle exec rspec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/TwilightCoders/active_registry>. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
