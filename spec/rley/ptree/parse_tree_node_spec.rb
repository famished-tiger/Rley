require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/parse_tree_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe ParseTreeNode do
      let(:sample_symbol) { double('fake-symbol') }
      let(:sample_range) { { low: 0, high: 5 } }

      subject { ParseTreeNode.new(sample_symbol, sample_range) }

      context 'Initialization:' do
        it 'should be created with a symbol and a range' do
          args = [ sample_symbol, sample_range ]
          expect { ParseTreeNode.new(*args) }.not_to raise_error
        end

        it 'should know its symbol' do
          expect(subject.symbol).to eq(sample_symbol)
        end

        it 'should know its range' do
          expect(subject.range).to eq(sample_range)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
