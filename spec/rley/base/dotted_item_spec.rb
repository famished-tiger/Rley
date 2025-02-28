# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'

# Load the class under test
require_relative '../../../lib/rley/base/dotted_item'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Base # Open this namespace to avoid module qualifier prefixes
    describe DottedItem do
      # Factory method. Builds a production with given left-hand side (LHS)
      # and given RHS (right-hand side)
      def build_prod(theLHS, *theRHSSymbols)
        return Syntax::Production.new(theLHS, theRHSSymbols)
      end

      let(:t_a) { Syntax::Terminal.new('A') }
      let(:t_b) { Syntax::Terminal.new('B') }
      let(:t_c) { Syntax::Terminal.new('C') }
      let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, t_b, t_c) }
      let(:other_prod) {  build_prod(nt_sentence, t_a) }
      let(:empty_prod) { build_prod(nt_sentence) }

      # Default instantiation rule
      subject(:an_item) { described_class.new(sample_prod, 1) }

      context 'Initialization:' do
        it 'is created with a production and an index' do
          expect { described_class.new(sample_prod, 0) }.not_to raise_error
          expect { described_class.new(sample_prod, 3) }.not_to raise_error
        end

        it 'complains when the index is out-of-bounds' do
          err = StandardError
          msg = 'Out of bound index'
          expect { described_class.new(sample_prod, 4) }.to raise_error(err, msg)
        end

        it 'knows its production' do
          expect(an_item.production).to eq(sample_prod)
        end

        it 'knows the lhs of the production' do
          expect(an_item.lhs).to eq(sample_prod.lhs)
        end

        it 'knows its position' do
          # At start position
          instance1 = described_class.new(sample_prod, 0)
          expect(instance1.position).to eq(0)

          # At (before) last symbol
          instance2 = described_class.new(sample_prod, 2)
          expect(instance2.position).to eq(2)

          # After all symbols in rhs
          instance3 = described_class.new(sample_prod, 3)
          expect(instance3.position).to eq(-1)

          # At start/end at the same time (production is empty)
          instance4 = described_class.new(build_prod(nt_sentence), 0)
          expect(instance4.position).to eq(-2)
        end
      end # context

      context 'Provided service:' do
        it 'knows whether its dot is at start position' do
          expect(an_item).not_to be_at_start

          # At start position
          instance1 = described_class.new(sample_prod, 0)
          expect(instance1).to be_at_start

          # At start/end at the same time (production is empty)
          instance2 = described_class.new(build_prod(nt_sentence), 0)
          expect(instance2).to be_at_start
        end

        it 'knows whether it is a reduce item' do
          expect(an_item).not_to be_reduce_item

          first_instance = described_class.new(sample_prod, 3)
          expect(first_instance).to be_reduce_item

          second_instance = described_class.new(empty_prod, 0)
          expect(second_instance).to be_reduce_item
        end

        it 'knows the symbol before the dot' do
          expect(an_item.prev_symbol).to eq(t_a)

          # Case of an empty production
          instance = described_class.new(empty_prod, 0)
          expect(instance.prev_symbol).to be_nil

          # Case of a dot at start position
          instance = described_class.new(sample_prod, 0)
          expect(instance.prev_symbol).to be_nil
        end

        it 'knows the symbol after the dot' do
          expect(an_item.next_symbol).to eq(t_b)
        end

        it 'calculates the previous position of the dot' do
          expect(an_item.prev_position).to eq(0)

          # Case of an empty production
          instance = described_class.new(empty_prod, 0)
          expect(instance.prev_position).to be_nil

          # Case of a dot at start position
          instance = described_class.new(sample_prod, 0)
          expect(instance.prev_position).to be_nil

          # Case of single symbol production
          instance = described_class.new(other_prod, 1)
          expect(instance.prev_position).to eq(0)
        end

        it 'determines if it is a successor of another dotted item' do
          expect(an_item).not_to be_successor_of(an_item)

          # Case: different productions
          instance = described_class.new(empty_prod, 0)
          expect(an_item).not_to be_successor_of(instance)

          # Case: one position difference
          instance = described_class.new(sample_prod, 0)
          expect(an_item).to be_successor_of(instance)
          expect(instance).not_to be_successor_of(an_item)

          # Case: more than one position difference
          instance2 = described_class.new(sample_prod, 2)
          expect(instance).not_to be_successor_of(instance2)
          expect(an_item).not_to be_successor_of(instance2)
          expect(instance2).to be_successor_of(an_item)
        end



        it 'gives its text representation' do
          expectation = 'sentence => A . B C'
          expect(an_item.to_s).to eq(expectation)
        end
      end
    end # describe
  end # module
end # module

# End of file
