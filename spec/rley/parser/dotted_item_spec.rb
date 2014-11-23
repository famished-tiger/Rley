require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'

# Load the class under test
require_relative '../../../lib/rley/parser/dotted_item'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
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
      subject { DottedItem.new(sample_prod, 1) }

      context 'Initialization:' do
        it 'should be created with a production and an index' do
          expect { DottedItem.new(sample_prod, 0) }.not_to raise_error
          expect { DottedItem.new(sample_prod, 3) }.not_to raise_error
        end

        it 'should complain when the index is out-of-bounds' do
          err = StandardError
          msg = 'Out of bound index'
          expect { DottedItem.new(sample_prod, 4) }.to raise_error(err, msg)
        end

        it 'should know its production' do
          expect(subject.production).to eq(sample_prod)
        end
        
        it 'should know the lhs of the production' do
          expect(subject.lhs).to eq(sample_prod.lhs)
        end

        it 'should know its position' do
          # At start position
          instance1 = DottedItem.new(sample_prod, 0)
          expect(instance1.position).to eq(0)

          # At (before) last symbol
          instance2 = DottedItem.new(sample_prod, 2)
          expect(instance2.position).to eq(2)

          # After all symbols in rhs
          instance3 = DottedItem.new(sample_prod, 3)
          expect(instance3.position).to eq(-1)

          # At start/end at the same time (production is empty)
          instance4 = DottedItem.new(build_prod(nt_sentence), 0)
          expect(instance4.position).to eq(-2)
        end

      end # context

      context 'Provided service:' do
        it 'should whether its dot is at start position' do
          expect(subject).not_to be_at_start
          
          # At start position
          instance1 = DottedItem.new(sample_prod, 0)
          expect(instance1).to be_at_start
          
          # At start/end at the same time (production is empty)
          instance2 = DottedItem.new(build_prod(nt_sentence), 0)
          expect(instance2).to be_at_start
        end

        it 'should whether it is a reduce item' do
          expect(subject).not_to be_reduce_item

          first_instance = DottedItem.new(sample_prod, 3)
          expect(first_instance).to be_reduce_item

          second_instance = DottedItem.new(empty_prod, 0)
          expect(second_instance).to be_reduce_item
        end

        it 'should know the symbol after the dot' do
          expect(subject.next_symbol).to eq(t_b)
        end
        
        it 'should give its text representation' do
          expectation = 'sentence => A . B C'
          expect(subject.to_s).to eq(expectation)
        end
      end

    end # describe
  end # module
end # module

# End of file
