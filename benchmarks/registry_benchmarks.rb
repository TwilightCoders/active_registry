#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark/ips'
require_relative '../lib/registry'

# Sample data structures for benchmarking
Person = Struct.new(:id, :name, :email, :age, :department)
Product = Struct.new(:id, :name, :price, :category, :brand)

def generate_people(count)
  names = %w[Alice Bob Charlie Diana Eve Frank Grace Henry Ivy Jack Kelly Liam]
  emails = %w[alice bob charlie diana eve frank grace henry ivy jack kelly liam]
  departments = %w[Engineering Marketing Sales Support HR Finance]

  Array.new(count) do |i|
    name = names.sample
    Person.new(
      i + 1,
      "#{name}#{i}",
      "#{emails.sample}#{i}@company.com",
      rand(22..65),
      departments.sample
    )
  end
end

def generate_products(count)
  names = %w[Widget Gadget Tool Device Component Module System]
  categories = %w[Electronics Tools Software Hardware]
  brands = %w[TechCorp InnovateLtd QualityBrand ReliableCo]

  Array.new(count) do |i|
    Product.new(
      i + 1,
      "#{names.sample} #{i}",
      rand(10.0..1000.0).round(2),
      categories.sample,
      brands.sample
    )
  end
end

puts '=== Registry Performance Benchmarks ==='
puts

# Test data sizes
SMALL_SIZE = 100
MEDIUM_SIZE = 1_000
LARGE_SIZE = 10_000

small_people = generate_people(SMALL_SIZE)
medium_people = generate_people(MEDIUM_SIZE)
large_people = generate_people(LARGE_SIZE)

puts '1. Registry Creation Performance'
puts '=' * 50

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report("Create registry (#{SMALL_SIZE} items)") do
    Registry.new(small_people.dup)
  end

  x.report("Create registry (#{MEDIUM_SIZE} items)") do
    Registry.new(medium_people.dup)
  end

  x.report("Create registry (#{LARGE_SIZE} items)") do
    Registry.new(large_people.dup)
  end

  x.compare!
end

puts "\n2. Indexing Performance"
puts '=' * 50

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  Registry.new(small_people.dup)
  Registry.new(medium_people.dup)
  Registry.new(large_people.dup)

  x.report("Index single field (#{SMALL_SIZE} items)") do
    r = Registry.new(small_people.dup)
    r.index(:name)
  end

  x.report("Index single field (#{MEDIUM_SIZE} items)") do
    r = Registry.new(medium_people.dup)
    r.index(:name)
  end

  x.report("Index single field (#{LARGE_SIZE} items)") do
    r = Registry.new(large_people.dup)
    r.index(:name)
  end

  x.report("Index multiple fields (#{MEDIUM_SIZE} items)") do
    r = Registry.new(medium_people.dup)
    r.index(:name, :department, :age)
  end

  x.compare!
end

puts "\n3. Query Performance"
puts '=' * 50

# Setup registries with indexes
small_registry = Registry.new(small_people.dup)
small_registry.index(:name, :department, :age)

medium_registry = Registry.new(medium_people.dup)
medium_registry.index(:name, :department, :age)

large_registry = Registry.new(large_people.dup)
large_registry.index(:name, :department, :age)

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  # Query by name (likely to return few results)
  x.report("where(name) - #{SMALL_SIZE} items") do
    small_registry.where(name: small_people.first.name)
  end

  x.report("where(name) - #{MEDIUM_SIZE} items") do
    medium_registry.where(name: medium_people.first.name)
  end

  x.report("where(name) - #{LARGE_SIZE} items") do
    large_registry.where(name: large_people.first.name)
  end

  # Query by department (likely to return many results)
  x.report("where(department) - #{MEDIUM_SIZE} items") do
    medium_registry.where(department: 'Engineering')
  end

  # Compound query
  x.report("compound where - #{MEDIUM_SIZE} items") do
    medium_registry.where(department: 'Engineering', age: 30)
  end

  x.compare!
end

puts "\n4. exists? Performance"
puts '=' * 50

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report("exists?(name) - #{SMALL_SIZE} items") do
    small_registry.exists?(name: small_people.first.name)
  end

  x.report("exists?(name) - #{MEDIUM_SIZE} items") do
    medium_registry.exists?(name: medium_people.first.name)
  end

  x.report("exists?(name) - #{LARGE_SIZE} items") do
    large_registry.exists?(name: large_people.first.name)
  end

  x.report("exists?(nonexistent) - #{MEDIUM_SIZE} items") do
    medium_registry.exists?(name: 'NonexistentName')
  end

  x.compare!
end

puts "\n5. Item Addition Performance"
puts '=' * 50

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  x.report('Add to small registry') do
    r = Registry.new(small_people[0, 50].dup)
    r.index(:name, :department)
    new_person = Person.new(999, 'NewPerson', 'new@test.com', 25, 'Engineering')
    r.add(new_person)
  end

  x.report('Add to medium registry') do
    r = Registry.new(medium_people[0, 500].dup)
    r.index(:name, :department)
    new_person = Person.new(999, 'NewPerson', 'new@test.com', 25, 'Engineering')
    r.add(new_person)
  end

  x.compare!
end

puts "\n6. Method Watching Overhead"
puts '=' * 50

Benchmark.ips do |x|
  x.config(time: 3, warmup: 1)

  # Registry without indexes (no method watching)
  x.report('Registry without indexes') do
    r = Registry.new(small_people[0, 50].dup)
    r.to_a.size
  end

  # Registry with indexes (method watching enabled)
  x.report('Registry with indexes') do
    r = Registry.new(small_people[0, 50].dup)
    r.index(:name, :department)
    r.to_a.size
  end

  x.compare!
end

puts "\nBenchmarks completed!"
puts 'Note: Higher operations per second (ops/sec) is better'
