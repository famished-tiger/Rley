require_relative '../../spec_helper'

require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/syntax/grammar_builder'
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


      subject do
        ParseTreeFactory.new(sample_result)
      end

      # Emit a text representation of the current path.
      def path_to_s()
        text_parts = subject.curr_path.map do |path_element|
          path_element.to_string(0)
        end
        return text_parts.join('/')
      end


      context 'Initialization:' do
        it 'should be created with a GFGParsing' do
          expect { ParseTreeFactory.new(sample_result) }.not_to raise_error
        end

        it 'should know the parse result' do
          expect(subject.parsing).to eq(sample_result)
        end
      end

      context 'Parse tree construction' do
        it 'should build a parse tree' do
          forest = subject.create
          expect(forest).to be_kind_of(PTree::ParseTree)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
