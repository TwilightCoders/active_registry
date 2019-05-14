require_relative 'lib/registry'

Gem::Specification.new do |spec|
  spec.name          = "registry"
  spec.version       = Registry::VERSION
  spec.authors       = ["Dale Stevens"]
  spec.email         = ["dale@twilightcoders.net"]

  spec.summary       = %q{Data structure for quick item lookup via indexes.}
  # spec.description   = %q{}
  spec.homepage      = "https://github.com/TwilightCoders/registry."
  spec.license       = "MIT"

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files         = Dir['CHANGELOG.md', 'README.md', 'LICENSE', 'lib/**/*']
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'spec']

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'pry-byebug', '~> 3'
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', "~> 3.0"
end
