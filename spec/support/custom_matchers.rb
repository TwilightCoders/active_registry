# frozen_string_literal: true

RSpec::Matchers.define :contain_mappings do |expected_mappings|
  match do |registry|
    expected_mappings.each do |index_name, expected_mapping|
      expected_mapping.each do |index, expected|
        actual = registry.where(index_name => index).to_a

        actual.sort! { |a, b| a.object_id <=> b.object_id }
        expected.sort! { |a, b| a.object_id <=> b.object_id }

        return false unless actual == expected
      end
    end

    true
  end
end
