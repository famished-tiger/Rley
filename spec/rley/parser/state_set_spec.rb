require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/parse_state'

# Load the class under test
require_relative '../../../lib/rley/parser/state_set'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes

  describe StateSet do
    let(:dotted_rule1) { double('fake_dotted_rule1') }
    let(:state1) { ParseState.new(dotted_rule1, 2) }
    let(:dotted_rule2) { double('fake_dotted_rule2') }
    let(:state2) { ParseState.new(dotted_rule2, 5) }

    context 'Initialization:' do

      it 'should be created without argument' do
        expect { StateSet.new }.not_to raise_error
      end
    end # context

    context 'Provided services:' do

      it 'should push a state' do
        expect(subject.states).to be_empty
        expect { subject.push_state(state1) }.not_to raise_error
        expect(subject).not_to be_empty
        subject.push_state(state2)
        expect(subject.states).to eq([state1, state2])
      end

      it 'should list the states expecting a given terminal' do
        # Case of no state
        expect(subject.states_expecting(:a)).to be_empty

        # Adding states
        subject.push_state(state1)
        subject.push_state(state2)
        allow(dotted_rule1).to receive(:next_symbol).and_return(:b)
        allow(dotted_rule2).to receive(:next_symbol).and_return(:a)
        expect(subject.states_expecting(:a)).to eq([state2])
        expect(subject.states_expecting(:b)).to eq([state1])
      end

      it 'should list the states related to a production' do
        a_prod = double('fake-production')

        # Case of no state
        expect(subject.states_for(a_prod)).to be_empty

        # Adding states
        subject.push_state(state1)
        subject.push_state(state2)
        allow(dotted_rule1).to receive(:production).and_return(:dummy)
        allow(dotted_rule2).to receive(:production).and_return(a_prod)
        expect(subject.states_for(a_prod)).to eq([state2])
      end

    end # context

  end # describe

  end # module
end # module

# End of file