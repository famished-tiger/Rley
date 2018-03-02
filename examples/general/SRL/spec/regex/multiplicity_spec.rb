# File: Multiplicity_spec.rb

require_relative '../spec_helper' # Use the RSpec test framework
require_relative '../../lib/regex/multiplicity'

module SRL
  # Reopen the module, in order to get rid of fully qualified names
  module Regex # This module is used as a namespace
    describe Multiplicity do
      context 'Creation & initialisation' do
        it 'should be created with 3 arguments' do
          # Valid cases: initialized with two integer values and a policy symbol
          %i[greedy lazy possessive].each do |aPolicy|
            expect { Multiplicity.new(0, 1, aPolicy) }.not_to raise_error
          end

          # Invalid case: initialized with invalid policy value
          err = StandardError
          msg = "Invalid repetition policy 'KO'."
          expect { Multiplicity.new(0, :more, 'KO') }.to raise_error(err, msg)
        end
      end

      context 'Provided services' do
        it 'should know its text representation' do
          policy2text = { greedy: '', lazy: '?', possessive: '+' }

          # Case: zero or one
          policy2text.each_key do |aPolicy|
            multi = Multiplicity.new(0, 1, aPolicy)
            expect(multi.to_str).to eq("?#{policy2text[aPolicy]}")
          end

          # Case: zero or more
          policy2text.each_key do |aPolicy|
            multi = Multiplicity.new(0, :more, aPolicy)
            expect(multi.to_str).to eq("*#{policy2text[aPolicy]}")
          end

          # Case: one or more
          policy2text.each_key do |aPolicy|
            multi = Multiplicity.new(1, :more, aPolicy)
            expect(multi.to_str).to eq("+#{policy2text[aPolicy]}")
          end

          # Case: exactly m times
          policy2text.each_key do |aPolicy|
            samples = [1, 2, 5, 100]
            samples.each do |aCount|
              multi = Multiplicity.new(aCount, aCount, aPolicy)
              expect(multi.to_str).to eq("{#{aCount}}#{policy2text[aPolicy]}")
            end
          end

          # Case: m, n times
          policy2text.each_key do |aPolicy|
            samples = [1, 2, 5, 100]
            samples.each do |aCount|
              upper = aCount + 1 + rand(20)
              multi = Multiplicity.new(aCount, upper, aPolicy)
              expectation = "{#{aCount},#{upper}}#{policy2text[aPolicy]}"
              expect(multi.to_str).to eq(expectation)
            end
          end

          # Case: m or more
          policy2text.each_key do |aPolicy|
            samples = [2, 3, 5, 100]
            samples.each do |aCount|
              multi = Multiplicity.new(aCount, :more, aPolicy)
              expect(multi.to_str).to eq("{#{aCount},}#{policy2text[aPolicy]}")
            end
          end
        end
      end
    end
  end # module
end # module
# End of file
