# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/lexical/token_range'

# Load the class under test
require_relative '../../../lib/rley/sppf/non_terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module SPPF # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalNode do
      # Factory method. Generate a range from its boundary values.
      def range(low, high)
        return Lexical::TokenRange.new(low: low, high: high)
      end

      subject(:a_node) { described_class.new(sample_symbol, sample_range) }

      let(:sample_symbol) do
        Syntax::NonTerminal.new('VP')
      end
      let(:sample_range) { range(0, 3) }

      context 'Initialization:' do
        it 'knows its non-terminal symbol' do
          expect(a_node.symbol).to eq(sample_symbol)
        end

        it 'knows its token range' do
          expect(a_node.range).to eq(sample_range)
          expect(a_node.origin).to eq(sample_range.low)
        end

        it "doesn't have children yet" do
          expect(a_node.subnodes).to be_empty
        end

        it 'has :and refinement' do
          expect(a_node.refinement).to eq(:and)
        end
      end # context

      context 'Provided services:' do
        it 'accepts the addition of subnodes' do
          subnode1 = double('first_subnode')
          subnode2 = double('second_subnode')
          subnode3 = double('third_subnode')
          expect { a_node.add_subnode(subnode1) }.not_to raise_error
          a_node.add_subnode(subnode2)
          a_node.add_subnode(subnode3)
          expect(a_node.subnodes).to eq([subnode3, subnode2, subnode1])
        end

        it 'has a string representation' do
          expect(a_node.to_string(0)).to eq('VP[0, 3]')
        end

        it 'returns a key value of itself' do
          expect(a_node.key).to eq('VP[0, 3]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
