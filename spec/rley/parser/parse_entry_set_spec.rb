# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/base/dotted_item'
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

      subject(:a_set) { described_class.new }

      let(:t_a) { Rley::Syntax::Terminal.new('a') }
      let(:t_b) { Rley::Syntax::Terminal.new('b') }
      let(:t_c) { Rley::Syntax::Terminal.new('c') }
      let(:nt_rep_c) { Rley::Syntax::NonTerminal.new('Repetition') }
      let(:repeated_prod) { build_prod(nt_rep_c, t_c, nt_rep_c) }
      let(:nt_sentence) { Rley::Syntax::NonTerminal.new('Sentence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, t_b, t_b, nt_rep_c) }

      let(:sample_item1) { Base::DottedItem.new(sample_prod, 1) }
      let(:sample_item2) { Base::DottedItem.new(sample_prod, 2) }
      let(:sample_item3) { Base::DottedItem.new(sample_prod, 3) }

      let(:vertex1) { GFG::ItemVertex.new(sample_item1) }
      let(:entry1) { ParseEntry.new(vertex1, 2) }
      let(:vertex2) { GFG::ItemVertex.new(sample_item2) }
      let(:entry2) { ParseEntry.new(vertex2, 3) }
      let(:vertex3) { GFG::ItemVertex.new(sample_item3) }
      let(:entry3) { ParseEntry.new(vertex3, 4) }

      context 'Initialization:' do
        it 'is created without argument' do
          expect { described_class.new }.not_to raise_error
        end

        it 'is empty after creation' do
          expect(a_set.entries).to be_empty
        end
      end # context

      context 'Provided services:' do
        it 'accepts the addition of an entry' do
          # Case: first time entry addition
          expect(a_set.push_entry(entry1)).to eq(entry1)
          expect(a_set).not_to be_empty

          # Case: duplicate entry
          expect(a_set.push_entry(entry1)).to eq(entry1)

          # Yet another entry
          expect(a_set.push_entry(entry2)).to eq(entry2)
          expect(a_set.entries).to eq([entry1, entry2])
        end

        it 'retrieves the entry at given position' do
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          expect(a_set[0]).to eq(entry1)
          expect(a_set[1]).to eq(entry2)
        end

        it 'lists the entries expecting a given terminal' do
          # Case: an entry expecting a terminal
          a_set.push_entry(entry1)
          expect(a_set.entries4term(t_b)).to eq([entry1])

          # Case: a second entry expecting same terminal
          a_set.push_entry(entry2)
          expect(a_set.entries4term(t_b)).to eq([entry1, entry2])
        end

        it 'lists the expected terminals' do
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          a_set.push_entry(entry3)

          expect(a_set.expected_terminals).to eq([t_b])
        end

        it 'lists the entries expecting a given non-terminal' do
          # Case: an entry expecting a non-terminal
          a_set.push_entry(entry3)
          expect(a_set.entries4n_term(nt_rep_c)).to eq([entry3])
        end

        it 'provides human-readable representation of itself' do
          # Case 1: empty set
          pattern_empty = /^#<Rley::Parser::ParseEntrySet:\d+ @entries=\[\]>$/
          expect(a_set.inspect).to match(pattern_empty)

          # Case 2: non-empty set
          a_set.push_entry(entry1)
          prefix = /^#<Rley::Parser::ParseEntrySet:\d+ @entries=\[#<Rley/
          expect(a_set.inspect).to match(prefix)
          pattern_entry = /ParseEntry:\d+ @vertex=<Rley::GFG::ItemVertex:\d+/
          expect(a_set.inspect).to match(pattern_entry)
          suffix = /=> a \. b b Repetition> @origin=2 @antecedents=\[\]>\]>$/
          expect(a_set.inspect).to match(suffix)
        end

=begin
        it 'lists of ambiguous states' do
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')
          expect(a_set.ambiguities.size).to eq(0)

          # Adding states
          a_set.push_entry(entry1)
          expect(vertex1).to receive(:production).and_return(prod1)
          expect(vertex1).to receive(:"reduce_item?").and_return(true)
          expect(vertex1).to receive(:lhs).and_return(:something)
          expect(a_set.ambiguities.size).to eq(0)
          expect(vertex2).to receive(:production).and_return(prod2)
          expect(vertex2).to receive(:"reduce_item?").and_return(true)
          expect(vertex2).to receive(:lhs).and_return(:something_else)
          a_set.push_entry(entry2)
          expect(a_set.ambiguities.size).to eq(0)
          # dotted_rule3 = double('fake_dotted_rule3')
          # expect(dotted_rule3).to receive(:production).and_return(prod2)
          # expect(dotted_rule3).to receive(:"reduce_item?").and_return(true)
          # expect(dotted_rule3).to receive(:lhs).and_return(:something_else)
          # entry3 = ParseEntry.new(dotted_rule3, 5)
          a_set.push_entry(entry3)
          expect(a_set.ambiguities[0]).to eq([entry2, entry3])
        end
=end
=begin
        it 'lists the states expecting a given terminal' do
          # Case of no state
          expect(a_set.states_expecting(:a)).to be_empty

          # Adding states
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          expect(vertex1).to receive(:next_symbol).and_return(:b)
          expect(vertex2).to receive(:next_symbol).and_return(:a)
          expect(a_set.states_expecting(:a)).to eq([entry2])
          expect(a_set.states_expecting(:b)).to eq([entry1])
        end

        it 'lists the states related to a production' do
          a_prod = double('fake-production')

          # Case of no state
          expect(a_set.states_for(a_prod)).to be_empty

          # Adding states
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          expect(vertex1).to receive(:production).and_return(:dummy)
          expect(vertex2).to receive(:production).and_return(a_prod)
          expect(a_set.states_for(a_prod)).to eq([entry2])
        end

        it 'lists the states that rewrite a given non-terminal' do
          non_term = double('fake-non-terminal')
          prod1 = double('fake-production1')
          prod2 = double('fake-production2')

          # Adding states
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          expect(vertex1).to receive(:production).and_return(prod1)
          expect(prod1).to receive(:lhs).and_return(:dummy)
          expect(vertex2).to receive(:production).and_return(prod2)
          expect(vertex2).to receive(:reduce_item?).and_return(true)
          expect(prod2).to receive(:lhs).and_return(non_term)
          expect(a_set.states_rewriting(non_term)).to eq([entry2])
        end



        it 'complains when impossible predecessor of parse state' do
          a_set.push_entry(entry1)
          a_set.push_entry(entry2)
          expect(vertex1).to receive(:prev_position).and_return(nil)
          err = StandardError
          expect { a_set.predecessor_state(entry1) }.to raise_error(err)
        end
=end
      end # context
    end # describe
  end # module
end # module

# End of file
