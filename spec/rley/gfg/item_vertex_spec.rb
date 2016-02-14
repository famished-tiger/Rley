require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/dotted_item'

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

      let(:t_a) { Rley::Syntax::Terminal.new('A') }
      let(:t_b) { Rley::Syntax::Terminal.new('B') }
      let(:t_c) { Rley::Syntax::Terminal.new('C') }
      let(:nt_sentence) { Rley::Syntax::NonTerminal.new('sentence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, t_b, t_c) }
      let(:other_prod) {  build_prod(nt_sentence, t_a) }
      let(:empty_prod) { build_prod(nt_sentence) }
      let(:sample_item) { Parser::DottedItem.new(sample_prod, 1) }
      subject { ItemVertex.new(sample_item) }

      context 'Initialization:' do
        it 'should be created with a dotted item' do
          expect { ItemVertex.new(sample_item) }.not_to raise_error
        end

        it 'should know its dotted item' do
          expect(subject.dotted_item).to eq(sample_item)
        end
      end # context
      
      context 'Provided services:' do
        it 'should know its label' do
          expect(subject.label).to eq(sample_item.to_s)
        end
        
        
      end # context      
    end # describe
  end # module
end # module

# End of file
