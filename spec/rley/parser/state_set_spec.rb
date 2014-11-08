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
      
      it 'should add state' do
        expect(subject.states).to be_empty
        expect { subject.add_state(state1) }.not_to raise_error
        expect(subject).not_to be_empty
        subject.add_state(state2)
        expect(subject.states).to eq([state1, state2])
      end

    end # context
    
  end # describe

  end # module
end # module

# End of file