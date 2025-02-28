# frozen_string_literal: true

require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/item_vertex'
require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/lexical/token_range'
require_relative '../../../lib/rley/base/dotted_item'

# Load the class under test
require_relative '../../../lib/rley/sppf/alternative_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module SPPF # Open this namespace to avoid module qualifier prefixes
    describe AlternativeNode do
      # Factory method. Generate a range from its boundary values.
      def range(low, high)
        return Lexical::TokenRange.new(low: low, high: high)
      end

      subject(:alt_node) { described_class.new(sample_vertex, sample_range) }

      let(:t_a) { Syntax::Terminal.new('A') }
      let(:t_b) { Syntax::Terminal.new('B') }
      let(:t_c) { Syntax::Terminal.new('C') }
      let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }
      let(:sample_prod) do
        Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
      end
      let(:sample_item) { Base::DottedItem.new(sample_prod, 3) }
      let(:sample_vertex) { GFG::ItemVertex.new(sample_item) }
      let(:sample_range) { range(0, 3) }

      context 'Construction:' do
        it 'is created with a item vertex and a token range' do
          expect { described_class.new(sample_vertex, sample_range) }
            .not_to raise_error
        end
      end

      context 'Initialization:' do
        it 'knows its token range' do
          expect(alt_node.range).to eq(sample_range)
          expect(alt_node.origin).to eq(sample_range.low)
        end

        it "doesn't have children yet" do
          expect(alt_node.subnodes).to be_empty
        end
      end # context

      context 'Provided services:' do
        it 'accepts the addition of subnodes' do
          subnode1 = double('first_subnode')
          subnode2 = double('second_subnode')
          subnode3 = double('third_subnode')
          expect { alt_node.add_subnode(subnode1) }.not_to raise_error
          alt_node.add_subnode(subnode2)
          alt_node.add_subnode(subnode3)
          expect(alt_node.subnodes).to eq([subnode3, subnode2, subnode1])
        end


        it 'has a string representation' do
          expect(alt_node.to_string(0)).to eq('Alt(sentence => A B C .)[0, 3]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
