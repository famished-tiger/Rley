require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/gfg/item_vertex'
require_relative '../../../lib/rley/parser/parse_entry'

# Load the class under test
require_relative '../../../lib/rley/parser/parse_entry_set'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe ParseEntrySet do
      # Factory method. Builds a production with given left-hand side (LHS)
      # and given RHS (right-hand side)
      def build_prod(theLHS, *theRHSSymbols)
        return Syntax::Production.new(theLHS, theRHSSymbols)
      end

      let(:t_a) { Rley::Syntax::Terminal.new('a') }
      let(:t_b) { Rley::Syntax::Terminal.new('b') }
      let(:t_c) { Rley::Syntax::Terminal.new('c') }
      let(:nt_rep_c) { Rley::Syntax::NonTerminal.new('Repetition') }
      let(:repeated_prod) { build_prod(nt_rep_c, t_c, nt_rep_c) }
      let(:nt_sentence) { Rley::Syntax::NonTerminal.new('Sentence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, t_b, t_b, nt_rep_c) }

      let(:sample_item1) { Parser::DottedItem.new(sample_prod, 1) }
      let(:sample_item2) { Parser::DottedItem.new(sample_prod, 2) }
      let(:sample_item3) { Parser::DottedItem.new(sample_prod, 3) }

      let(:vertex1) { GFG::ItemVertex.new(sample_item1) }
      let(:entry1) { ParseEntry.new(vertex1, 2) }
      let(:vertex2) { GFG::ItemVertex.new(sample_item2) }
      let(:entry2) { ParseEntry.new(vertex2, 3) }
      let(:vertex3) { GFG::ItemVertex.new(sample_item3) }
      let(:entry3) { ParseEntry.new(vertex3, 4) }

      context 'Initialization:' do
        it 'should be created without argument' do
          expect { ParseEntrySet.new }.not_to raise_error
        end

        it 'should be empty after creation' do
          expect(subject.entries).to be_empty
        end
      end # context

      context 'Provided services:' do
        it 'should accept the addition of an entry' do
          # Case: first time e,try addition
          expect(subject.push_entry(entry1)).to eq(entry1)
          expect(subject).not_to be_empty

          # Case: duplicate entry
          expect(subject.push_entry(entry1)).to eq(entry1)

          # Yet another entry
          expect(subject.push_entry(entry2)).to eq(entry2)
          expect(subject.entries).to eq([entry1, entry2])
        end

        it 'should retrieve the entry at given position' do
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          expect(subject[0]).to eq(entry1)
          expect(subject[1]).to eq(entry2)
        end

        it 'should list the entries expecting a given terminal' do
          # Case: an entry expecting a terminal
          subject.push_entry(entry1)
          expect(subject.entries4term(t_b)).to eq([entry1])

          # Case: a second entry expecting same terminal
          subject.push_entry(entry2)
          expect(subject.entries4term(t_b)).to eq([entry1, entry2])
        end
        
        it 'should list the expected terminals' do
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          subject.push_entry(entry3)

          expect(subject.expected_terminals).to eq([t_b])
        end

        it 'should list the entries expecting a given non-terminal' do
          # Case: an entry expecting a non-terminal
          subject.push_entry(entry3)
          expect(subject.entries4n_term(nt_rep_c)).to eq([entry3])
        end

=begin
        it 'should list of ambiguous states' do
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')
          expect(subject.ambiguities.size).to eq(0)

          # Adding states
          subject.push_entry(entry1)
          expect(vertex1).to receive(:production).and_return(prod1)
          expect(vertex1).to receive(:"reduce_item?").and_return(true)
          expect(vertex1).to receive(:lhs).and_return(:something)
          expect(subject.ambiguities.size).to eq(0)
          expect(vertex2).to receive(:production).and_return(prod2)
          expect(vertex2).to receive(:"reduce_item?").and_return(true)
          expect(vertex2).to receive(:lhs).and_return(:something_else)
          subject.push_entry(entry2)
          expect(subject.ambiguities.size).to eq(0)
          # dotted_rule3 = double('fake_dotted_rule3')
          # expect(dotted_rule3).to receive(:production).and_return(prod2)
          # expect(dotted_rule3).to receive(:"reduce_item?").and_return(true)
          # expect(dotted_rule3).to receive(:lhs).and_return(:something_else)
          # entry3 = ParseEntry.new(dotted_rule3, 5)
          subject.push_entry(entry3)
          expect(subject.ambiguities[0]).to eq([entry2, entry3])
        end
=end
=begin
        it 'should list the states expecting a given terminal' do
          # Case of no state
          expect(subject.states_expecting(:a)).to be_empty

          # Adding states
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          expect(vertex1).to receive(:next_symbol).and_return(:b)
          expect(vertex2).to receive(:next_symbol).and_return(:a)
          expect(subject.states_expecting(:a)).to eq([entry2])
          expect(subject.states_expecting(:b)).to eq([entry1])
        end

        it 'should list the states related to a production' do
          a_prod = double('fake-production')

          # Case of no state
          expect(subject.states_for(a_prod)).to be_empty

          # Adding states
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          expect(vertex1).to receive(:production).and_return(:dummy)
          expect(vertex2).to receive(:production).and_return(a_prod)
          expect(subject.states_for(a_prod)).to eq([entry2])
        end

        it 'should list the states that rewrite a given non-terminal' do
          non_term = double('fake-non-terminal')
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')

          # Adding states
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          expect(vertex1).to receive(:production).and_return(prod1)
          expect(prod1).to receive(:lhs).and_return(:dummy)
          expect(vertex2).to receive(:production).and_return(prod2)
          expect(vertex2).to receive(:reduce_item?).and_return(true)
          expect(prod2).to receive(:lhs).and_return(non_term)
          expect(subject.states_rewriting(non_term)).to eq([entry2])
        end



        it 'should complain when impossible predecessor of parse state' do
          subject.push_entry(entry1)
          subject.push_entry(entry2)
          expect(vertex1).to receive(:prev_position).and_return(nil)
          err = StandardError
          expect { subject.predecessor_state(entry1) }.to raise_error(err)
        end
=end
      end # context
    end # describe
  end # module
end # module

# End of file
