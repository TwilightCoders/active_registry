# frozen_string_literal: true

require 'simplecov' # Will auto-load .simplecov config

require 'pry'

Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'registry'

RSpec.configure do |config|
end
