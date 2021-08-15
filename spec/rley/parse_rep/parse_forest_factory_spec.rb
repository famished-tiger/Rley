# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'

require_relative '../../../lib/rley/syntax/base_grammar_builder'
require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'

# Load the class under test
require_relative '../../../lib/rley/parse_rep/parse_forest_factory'

module Rley # Open this namespace to avoid module qualifier prefixes
  module ParseRep
    describe ParseForestFactory do
      include GrammarHelper     # Mix-in with token factory method
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      let(:sample_grammar) do
          # Grammar based on paper from Elisabeth Scott
          # "SPPF-Style Parsing From Earley Recognizers" in
          # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
          # contains a hidden left recursion and a cycle
          builder = Syntax::BaseGrammarBuilder.new do
            add_terminals('a', 'b')
            rule 'Phi' => 'S'
            rule 'S' => 'A T'
            rule 'S' => 'a T'
            rule 'A' => 'a'
            rule 'A' => 'B A'
            rule 'B' => []
            rule 'T' => 'b b b'
          end
          builder.grammar
      end

      let(:sample_tokens) do
        build_token_sequence(%w[a b b b], sample_grammar)
      end

      let(:sample_result) do
        parser = Parser::GFGEarleyParser.new(sample_grammar)
        parser.parse(sample_tokens)
      end

      subject do
        ParseForestFactory.new(sample_result)
      end

      # Emit a text representation of the current path.
      def path_to_s
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        text_parts.join('/')
      end

      context 'Initialization:' do
        it 'should be created with a GFGParsing' do
          expect { ParseForestFactory.new(sample_result) }.not_to raise_error
        end

        it 'should know the parse result' do
          expect(subject.parsing).to eq(sample_result)
        end
      end

      context 'Parse forest construction' do
        it 'should build a parse forest' do
          forest = subject.create
          expect(forest).to be_kind_of(SPPF::ParseForest)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
