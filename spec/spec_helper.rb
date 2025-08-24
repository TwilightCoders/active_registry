# frozen_string_literal: true

require 'pry'

require 'simplecov' # Will auto-load .simplecov config

Dir['./spec/support/**/*.rb'].each { |f| require f }

require 'registry'

RSpec.configure do |config|
end
