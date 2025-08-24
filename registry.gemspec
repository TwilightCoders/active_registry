# frozen_string_literal: true

require_relative 'lib/registry/version'

Gem::Specification.new do |spec|
  spec.name          = 'registry'
  spec.version       = Registry::VERSION
  spec.authors       = ['Dale Stevens']
  spec.email         = ['dale@twilightcoders.net']

  spec.summary       = 'Data structure for quick item lookup via indexes.'
  # spec.description   = %q{}
  spec.homepage      = 'https://github.com/TwilightCoders/registry.'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib spec]

  spec.required_ruby_version = '>= 3.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'simplecov-json', '~> 0.2'
end
