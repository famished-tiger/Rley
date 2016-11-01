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
        
        it 'should be empty at creation' do
          expect(subject.states).to be_empty
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
          expect(dotted_rule1).to receive(:next_symbol).and_return(:b)
          expect(dotted_rule2).to receive(:next_symbol).and_return(:a)
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
          expect(dotted_rule1).to receive(:production).and_return(:dummy)
          expect(dotted_rule2).to receive(:production).and_return(a_prod)
          expect(subject.states_for(a_prod)).to eq([state2])
        end
        
        it 'should list the states that rewrite a given non-terminal' do
          non_term = double('fake-non-terminal')
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')
        
          # Adding states
          subject.push_state(state1)
          subject.push_state(state2)
          expect(dotted_rule1).to receive(:production).and_return(prod1)
          expect(prod1).to receive(:lhs).and_return(:dummy)          
          expect(dotted_rule2).to receive(:production).and_return(prod2)
          expect(dotted_rule2).to receive(:reduce_item?).and_return(true)
          expect(prod2).to receive(:lhs).and_return(non_term) 
          expect(subject.states_rewriting(non_term)).to eq([state2])
        end
        
        it 'should list of ambiguous states' do
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')
          expect(subject.ambiguities.size).to eq(0)
          
          # Adding states
          subject.push_state(state1)
          expect(dotted_rule1).to receive(:production).and_return(prod1)
          expect(dotted_rule1).to receive(:"reduce_item?").and_return(true)
          expect(dotted_rule1).to receive(:lhs).and_return(:something)     
          expect(subject.ambiguities.size).to eq(0)
          expect(dotted_rule2).to receive(:production).and_return(prod2)
          expect(dotted_rule2).to receive(:"reduce_item?").and_return(true)
          expect(dotted_rule2).to receive(:lhs).and_return(:something_else)  
          subject.push_state(state2)
          expect(subject.ambiguities.size).to eq(0)
          dotted_rule3 = double('fake_dotted_rule3')
          expect(dotted_rule3).to receive(:production).and_return(prod2)
          expect(dotted_rule3).to receive(:"reduce_item?").and_return(true)
          expect(dotted_rule3).to receive(:lhs).and_return(:something_else)  
          state3 = ParseState.new(dotted_rule3, 5)
          subject.push_state(state3) 
          expect(subject.ambiguities[0]).to eq([state2, state3])          
        end
        
        it 'should complain when impossible predecessor of parse state' do
          subject.push_state(state1)
          subject.push_state(state2)
          expect(dotted_rule1).to receive(:prev_position).and_return(nil) 
          err = StandardError
          expect { subject.predecessor_state(state1) }.to raise_error(err)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
