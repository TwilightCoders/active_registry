#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'benchmark/ips'
require_relative '../lib/registry'

# Quick benchmark to identify main bottlenecks
Person = Struct.new(:id, :name, :email, :department)

def generate_people(count)
  Array.new(count) do |i|
    Person.new(i + 1, "Person#{i}", "person#{i}@test.com", %w[Eng Sales Marketing].sample)
  end
end

puts '=== Quick Performance Analysis ==='
puts

people100 = generate_people(100)
people1000 = generate_people(1000)

puts '1. Indexing Overhead Analysis'
puts '=' * 40

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report('Create registry (100, no indexes)') do
    Registry.new(people100.dup)
  end

  x.report('Create + index (100, 1 field)') do
    r = Registry.new(people100.dup)
    r.index(:name)
  end

  x.report('Create + index (100, 3 fields)') do
    r = Registry.new(people100.dup)
    r.index(:name, :email, :department)
  end

  x.compare!
end

puts "\n2. Method Watching Bottleneck"
puts '=' * 40

# Pre-create registries to isolate method watching cost
Registry.new(people100.dup)

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report('Add index to existing registry') do
    r = Registry.new(people100.dup)
    r.index(:name)
  end

  x.report('Query indexed registry') do
    r = Registry.new(people100.dup)
    r.index(:name)
    r.where(name: people100.first.name)
  end

  x.compare!
end

puts "\n3. Query Performance Scale"
puts '=' * 40

reg100 = Registry.new(people100.dup)
reg100.index(:name, :department)

reg1000 = Registry.new(people1000.dup)
reg1000.index(:name, :department)

Benchmark.ips do |x|
  x.config(time: 2, warmup: 1)

  x.report('where() - 100 items') do
    reg100.where(name: people100.first.name)
  end

  x.report('where() - 1000 items') do
    reg1000.where(name: people1000.first.name)
  end

  x.report('exists?() - 100 items') do
    reg100.exists?(name: people100.first.name)
  end

  x.report('exists?() - 1000 items') do
    reg1000.exists?(name: people1000.first.name)
  end

  x.compare!
end

puts "\nKey findings will help identify optimization targets!"
