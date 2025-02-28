# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../support/grammar_abc_helper'


# Load the class under test
require_relative '../../../lib/rley/ptree/parse_tree'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe ParseTree do
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      subject(:ptree) { described_class.new(sample_root) }

      let(:sample_grammar) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:sample_prod) { sample_grammar.rules[0] }
      let(:sample_range) { { low: 0, high: 5 } }
      let(:sample_root) { ParseTreeNode.new(sample_prod.lhs, sample_range) }

      context 'Initialization:' do
        it 'is created with a root node' do
          expect { described_class.new(sample_root) }.not_to raise_error
        end

        it 'knows its root node' do
          its_root = ptree.root
          expect(its_root.symbol.name).to eq('S')
          expect(its_root.range).to eq(sample_range)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
