require 'pry'

require 'simplecov'

Dir['./spec/support/**/*.rb'].each { |f| require f }
SimpleCov.start do
  add_filter 'spec'
end

require 'active_registry'

RSpec.configure do |config|
end
