require 'ostruct'
require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/tokens/token_range'

# Load the class under test
require_relative '../../../lib/rley/sppf/non_terminal_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module SPPF # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalNode do
      # Factory method. Generate a range from its boundary values.
      def range(low, high)
        return Tokens::TokenRange.new(low: low, high: high)
      end

      let(:sample_symbol) do
        Syntax::NonTerminal.new('VP')
      end
      let(:sample_range) { range(0, 3) }

      subject { NonTerminalNode.new(sample_symbol, sample_range) }

      context 'Initialization:' do
        it 'should know its non-terminal symbol' do
          expect(subject.symbol).to eq(sample_symbol)
        end

        it 'should know its token range' do
          expect(subject.range).to eq(sample_range)
          expect(subject.origin).to eq(sample_range.low)
        end

        it "shouldn't have children yet" do
          expect(subject.subnodes).to be_empty
        end
        
        it 'should have :and refinement' do
          expect(subject.refinement).to eq(:and)
        end
      end # context
      
      context 'Provided services:' do
        it 'should accept the addition of subnodes' do
          subnode1 = double('first_subnode')
          subnode2 = double('second_subnode')
          subnode3 = double('third_subnode')
          expect { subject.add_subnode(subnode1) }.not_to raise_error
          subject.add_subnode(subnode2)
          subject.add_subnode(subnode3)
          expect(subject.subnodes).to eq([subnode3, subnode2, subnode1])
        end

        it 'should have a string representation' do
          expect(subject.to_string(0)).to eq('VP[0, 3]')
        end
        
        it 'should return a key value of itself' do
          expect(subject.key).to eq('VP[0, 3]')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
