# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/base/dotted_item'
require_relative '../../../lib/rley/gfg/shortcut_edge'

# Load the class under test
require_relative '../../../lib/rley/gfg/item_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe ItemVertex do
      # Factory method. Builds a production with given left-hand side (LHS)
      # and given RHS (right-hand side)
      def build_prod(theLHS, *theRHSSymbols)
        return Syntax::Production.new(theLHS, theRHSSymbols)
      end
      subject(:a_vertex) { described_class.new(sample_item) }

      let(:t_a) { Rley::Syntax::Terminal.new('a') }
      let(:t_b) { Rley::Syntax::Terminal.new('b') }
      let(:t_c) { Rley::Syntax::Terminal.new('c') }
      let(:nt_sentence) { Rley::Syntax::NonTerminal.new('sentence') }
      let(:nt_b_sequence) { Rley::Syntax::NonTerminal.new('b_sequence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, nt_b_sequence, t_c) }
      let(:other_prod) {  build_prod(nt_sentence, t_a) }
      let(:recursive_prod) { build_prod(nt_b_sequence, nt_b_sequence, t_b) }
      let(:b_prod) { build_prod(nt_b_sequence, t_b) }
      let(:empty_prod) { build_prod(nt_sentence) }
      let(:sample_item) { Base::DottedItem.new(sample_prod, 1) }
      let(:next_item) { Base::DottedItem.new(sample_prod, 2) }

      context 'Initialization:' do
        it 'is created with a dotted item' do
          expect { described_class.new(sample_item) }.not_to raise_error
        end

        it 'knows its dotted item' do
          expect(a_vertex.dotted_item).to eq(sample_item)
        end

        it 'does not have any shortcut edge at start' do
          expect(a_vertex.shortcut).to be_nil
        end
      end # context

      context 'Provided services:' do
        it 'knows its label' do
          expect(a_vertex.label).to eq(sample_item.to_s)
        end

        it 'knows the lhs of the production' do
          expect(a_vertex.lhs).to eq(nt_sentence)
        end

        it 'knows whether it has a dot at the end of the rhs' do
          # Case: dot not at the end
          expect(a_vertex).not_to be_complete

          # Case: dot at the end
          instance1 = described_class.new(Base::DottedItem.new(sample_prod, 3))
          expect(instance1).to be_complete

          # Case: empty production
          instance2 = described_class.new(Base::DottedItem.new(empty_prod, 0))
          expect(instance2).to be_complete
        end

        it 'knows the previous symbol (if any) in the rhs (i)' do
          # Case: dot is after first symbol
          instance1 = described_class.new(sample_item)
          expect(instance1.prev_symbol).to eq(t_a)

          # Case: dot is after second or later symbol
          instance2 = described_class.new(next_item)
          expect(instance2.prev_symbol).to eq(nt_b_sequence)

          # Case: dot is at begin
          instance3 = described_class.new(Base::DottedItem.new(sample_prod, 0))
          expect(instance3.prev_symbol).to be_nil

          # Case: empty production
          instance4 = described_class.new(Base::DottedItem.new(empty_prod, 0))
          expect(instance4.prev_symbol).to be_nil
        end


        it 'knows the next symbol (if any) in the rhs (ii)' do
          # Case: dot is not penultimate
          expect(a_vertex.next_symbol).to eq(nt_b_sequence)

          # Case: dot is penultimate
          instance1 = described_class.new(next_item)
          expect(instance1.next_symbol).to eq(t_c)

          # Case: dot is at end
          instance2 = described_class.new(Base::DottedItem.new(sample_prod, 3))
          expect(instance2.next_symbol).to be_nil

          # Case: empty production
          instance3 = described_class.new(Base::DottedItem.new(empty_prod, 0))
          expect(instance3.next_symbol).to be_nil
        end

        it 'accepts a shortcut edge' do
          next_vertex = described_class.new(next_item)

          # The ShortcutEdge constructor invokes the shortcut setter
          shortcut = ShortcutEdge.new(a_vertex, next_vertex)
          expect(a_vertex.shortcut).to eq(shortcut)
        end

        it 'rejects an invalid shortcut edge' do
          err = StandardError
          err_msg = 'Invalid shortcut argument'
          expect { a_vertex.shortcut = 'invalid' }.to raise_error(err, err_msg)
        end

        it 'provides human-readable representation of itself' do
          prefix = /^#<Rley::GFG::ItemVertex:\d+/
          expect(a_vertex.inspect).to match(prefix)
          suffix = /label="sentence => a \. b_sequence c">$/
          expect(a_vertex.inspect).to match(suffix)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
