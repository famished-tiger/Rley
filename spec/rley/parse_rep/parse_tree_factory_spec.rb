# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/syntax/base_grammar_builder'
require_relative '../support/grammar_helper'
require_relative '../support/grammar_abc_helper'
require_relative '../support/expectation_helper'

# Load the class under test
require_relative '../../../lib/rley/parse_rep/parse_tree_factory'

module Rley # Open this namespace to avoid module qualifier prefixes
  module ParseRep
    describe ParseTreeFactory do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets
      include GrammarABCHelper  # Mix-in for a sample grammar

      subject(:a_factory) { described_class.new(sample_result) }

      let(:sample_grammar) do
        builder = grammar_abc_builder
        builder.grammar
      end
      let(:sample_tokens) do
        build_token_sequence(%w[a b c], sample_grammar)
      end
      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      # Emit a text representation of the current path.
      def path_to_s
        text_parts = a_factory.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        text_parts.join('/')
      end


      context 'Initialization:' do
        it 'is created with a GFGParsing' do
          expect { described_class.new(sample_result) }.not_to raise_error
        end

        it 'knows the parse result' do
          expect(a_factory.parsing).to eq(sample_result)
        end
      end

      context 'Parse tree construction' do
        it 'builds a parse tree' do
          forest = a_factory.create
          expect(forest).to be_a(PTree::ParseTree)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
