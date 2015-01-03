require_relative '../../spec_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/chart'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe Chart do
      let(:count_token) { 20 }
      let(:dotted_rule) { double('fake-dotted-item') }

      context 'Initialization:' do
        # Default instantiation rule
        subject { Chart.new(dotted_rule, count_token) }

        it 'should be created with a start dotted rule and a token count' do
          expect { Chart.new(dotted_rule, count_token) }.not_to raise_error
        end

        it 'should have a seed state in first state_set' do
          seed_state = ParseState.new(dotted_rule, 0)
          expect(subject[0].states).to eq([seed_state])

          # Shorthand syntax
          expect(subject[0].first).to eq(seed_state)
        end

        it 'should have the correct state_set count' do
          expect(subject.state_sets.size).to eq(count_token + 1)
        end

        it 'should know the start dotted rule' do
          expect(subject.start_dotted_rule).to eq(dotted_rule)
        end
        
        it 'should have at least one non-empty state set' do
          expect(subject.last_index).to eq(0)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
