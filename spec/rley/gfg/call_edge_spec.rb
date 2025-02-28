# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/base/dotted_item'
require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/gfg/item_vertex'

# Load the class under test
require_relative '../../../lib/rley/gfg/call_edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe CallEdge do
      # Factory method. Builds a production with given left-hand side (LHS)
      # and given RHS (right-hand side)
      def build_prod(theLHS, *theRHSSymbols)
        return Syntax::Production.new(theLHS, theRHSSymbols)
      end

      subject(:an_edge) { described_class.new(vertex1, vertex2) }

      let(:t_a) { Rley::Syntax::Terminal.new('a') }
      let(:t_b) { Rley::Syntax::Terminal.new('b') }
      let(:t_c) { Rley::Syntax::Terminal.new('c') }
      let(:nt_sentence) { Rley::Syntax::NonTerminal.new('sentence') }
      let(:nt_b_sequence) { Rley::Syntax::NonTerminal.new('b_sequence') }
      let(:sample_prod) { build_prod(nt_sentence, t_a, nt_b_sequence, t_c) }
      let(:sample_item) { Base::DottedItem.new(sample_prod, 1) }
      let(:vertex1) { ItemVertex.new(sample_item) }
      let(:vertex2) { StartVertex.new('to') }

      context 'Initialization:' do
        it 'is created with two vertice arguments' do
          expect { described_class.new(vertex1, vertex2) }.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'knows its key' do
          expectation = "CALL_#{sample_prod.object_id}_#{sample_item.position}"
          expect(an_edge.key).to eq(expectation)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
