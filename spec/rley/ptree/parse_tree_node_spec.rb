# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/ptree/parse_tree_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe ParseTreeNode do
      subject(:a_node) { described_class.new(sample_symbol, sample_range) }

      let(:sample_symbol) { double('fake-symbol') }
      let(:sample_range) { { low: 0, high: 5 } }

      context 'Initialization:' do
        it 'is created with a symbol and a range' do
          args = [sample_symbol, sample_range]
          expect { described_class.new(*args) }.not_to raise_error
        end

        it 'knows its symbol' do
          expect(a_node.symbol).to eq(sample_symbol)
        end

        it 'knows its range' do
          expect(a_node.range).to eq(sample_range)
        end
      end # context

      context 'Provided services:' do
        it 'assigns undefined range bounds' do
          partial_range = { low: 0 } # High bound left undefined
          instance = described_class.new(sample_symbol, partial_range)

          another = { low: 1, high: 4 } # High bound is specified
          instance.range = another
          expect(instance.range).to eq(low: 0, high: 4)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
