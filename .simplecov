# frozen_string_literal: true

# Load SimpleCov before anything else
require 'simplecov'
require 'simplecov-json'

SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
  add_filter 'benchmarks'

  if ENV['CI']
    formatter SimpleCov::Formatter::MultiFormatter.new([
                                                         SimpleCov::Formatter::HTMLFormatter,
                                                         SimpleCov::Formatter::JSONFormatter
                                                       ])
  end
end
