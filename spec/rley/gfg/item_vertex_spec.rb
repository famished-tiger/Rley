require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'
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
      let(:sample_item) { Parser::DottedItem.new(sample_prod, 1) }
      let(:next_item) { Parser::DottedItem.new(sample_prod, 2) }
      subject { ItemVertex.new(sample_item) }

      context 'Initialization:' do
        it 'should be created with a dotted item' do
          expect { ItemVertex.new(sample_item) }.not_to raise_error
        end

        it 'should know its dotted item' do
          expect(subject.dotted_item).to eq(sample_item)
        end

        it 'should not have any shortcut edge at start' do
          expect(subject.shortcut).to be_nil
        end
      end # context

      context 'Provided services:' do
        it 'should know its label' do
          expect(subject.label).to eq(sample_item.to_s)
        end

        it 'should know the lhs of the production' do
          expect(subject.lhs).to eq(nt_sentence)
        end

        it 'should know whether it has a dot at the end of the rhs' do
          # Case: dot not at the end
          expect(subject).not_to be_complete

          # Case: dot at the end
          instance1 = ItemVertex.new(Parser::DottedItem.new(sample_prod, 3))
          expect(instance1).to be_complete

          # Case: empty production
          instance2 = ItemVertex.new(Parser::DottedItem.new(empty_prod, 0))
          expect(instance2).to be_complete
        end

        it 'should know the previous symbol (if any) in the rhs' do
          # Case: dot is after first symbol
          instance1 = ItemVertex.new(sample_item)
          expect(instance1.prev_symbol).to eq(t_a)
          
          # Case: dot is after second or later symbol
          instance2 = ItemVertex.new(next_item)
          expect(instance2.prev_symbol).to eq(nt_b_sequence)          

          # Case: dot is at begin
          instance3 = ItemVertex.new(Parser::DottedItem.new(sample_prod, 0))
          expect(instance3.prev_symbol).to be_nil

          # Case: empty production
          instance4 = ItemVertex.new(Parser::DottedItem.new(empty_prod, 0))
          expect(instance4.prev_symbol).to be_nil
        end
        
        
        it 'should know the next symbol (if any) in the rhs' do
          # Case: dot is not penultimate
          expect(subject.next_symbol).to eq(nt_b_sequence)

          # Case: dot is penultimate
          instance1 = ItemVertex.new(next_item)
          expect(instance1.next_symbol).to eq(t_c)

          # Case: dot is at end
          instance2 = ItemVertex.new(Parser::DottedItem.new(sample_prod, 3))
          expect(instance2.next_symbol).to be_nil

          # Case: empty production
          instance3 = ItemVertex.new(Parser::DottedItem.new(empty_prod, 0))
          expect(instance3.next_symbol).to be_nil
        end

        it 'should accept a shortcut edge' do
          next_vertex = ItemVertex.new(next_item)

          # The ShortcutEdge constructor invokes the shortcut setter
          shortcut = ShortcutEdge.new(subject, next_vertex)
          expect(subject.shortcut).to eq(shortcut)
        end
        
        it 'should reject an invalid shortcut edge' do
          err = StandardError
          err_msg = 'Invalid shortcut argument'
          expect { subject.shortcut = 'invalid'}.to raise_error(err, err_msg)
        end        
      end # context
    end # describe
  end # module
end # module

# End of file
