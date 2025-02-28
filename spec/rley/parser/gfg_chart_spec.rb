# frozen_string_literal: true

require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/parser/parse_entry'
require_relative '../../../lib/rley/base/grm_items_builder'
require_relative '../../../lib/rley/gfg/grm_flow_graph'
require_relative '../support/grammar_abc_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/gfg_chart'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe GFGChart do
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      # Helper method. Create an array of dotted items
      # from the given grammar
      def build_items_for_grammar(aGrammar)
        helper = Object.new
        helper.extend(Base::GrmItemsBuilder)
        return helper.build_dotted_items(aGrammar)
      end

      # Default instantiation rule
      subject(:a_chart) { described_class.new(sample_gfg) }

      let(:count_token) { 20 }
      let(:output) { StringIO.new('', 'w') }

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:token_seq) do
        literals = %w[a a b c c]
        literals.map { |lexeme| Lexical::Token.new(lexeme, nil) }
      end

      # Helper method. Create an array of dotted items
      # from the abc grammar
      let(:items_from_grammar) { build_items_for_grammar(grammar_abc) }
      let(:sample_gfg) { GFG::GrmFlowGraph.new(items_from_grammar) }
      let(:sample_start_symbol) { sample_gfg.start_vertex.non_terminal }
      let(:second_vertex) { sample_gfg.start_vertex.edges[0].successor }

      context 'Initialization:' do
        it 'is created with start vertex, token count' do
          expect { described_class.new(sample_gfg) }.not_to raise_error
        end

        it 'has one entry set' do
          expect(a_chart.sets.size).to eq(1)
        end

        it 'knows the start symbol' do
          expect(a_chart.start_symbol).to eq(sample_start_symbol)
        end

        it 'knows the initial parse entry' do
          expect(a_chart.initial_entry.vertex).to eq(sample_gfg.start_vertex)
          expect(a_chart.initial_entry.origin).to eq(0)
        end
      end # context

      context 'Provided services:' do
        it 'accepts the pushing of a parse entry in existing set' do
          expect(a_chart.sets[0].entries.size).to eq(1)
          a_chart.push_entry(second_vertex, 0, 0, :scan_rule)
          expect(a_chart.sets[0].entries.size).to eq(2)
        end

        it 'accepts the pushing of a parse entry in new set' do
          expect(a_chart.sets[0].entries.size).to eq(1)
          a_chart.push_entry(second_vertex, 0, 1, :scan_rule)
          expect(a_chart.sets[0].entries.size).to eq(1)
          expect(a_chart.sets.size).to eq(2)
          expect(a_chart.sets[1].entries.size).to eq(1)
        end

        it 'retrieves an existing set at given position' do
          expect(a_chart[0]).to eq(a_chart.sets[0])
        end

        it 'returns a user-friendly text representation of itself' do
          a_chart.push_entry(second_vertex, 0, 1, :scan_rule)
          representation = <<REPR
State[0]
  .S | 0
State[1]
  S => . A | 0
REPR
          expect(a_chart.to_s).to eq(representation)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
