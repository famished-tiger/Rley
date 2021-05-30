# frozen_string_literal: true

require_relative '../../spec_helper'
require 'stringio'

require_relative '../support/grammar_abc_helper'
require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/ptree/parse_tree'
require_relative '../../../lib/rley/parse_tree_visitor'
# Load the class under test
require_relative '../../../lib/rley/formatter/json'

module Rley # Re-open the module to get rid of qualified names
  module Formatter
    describe Json do
      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        sandbox = Object.new
        sandbox.extend(GrammarABCHelper)
        builder = sandbox.grammar_abc_builder
        builder.grammar
      end

      # Variables for the terminal symbols
      let(:a_) { grammar_abc.name2symbol['a'] }
      let(:b_) { grammar_abc.name2symbol['b'] }
      let(:c_) { grammar_abc.name2symbol['c'] }

      # Helper method that mimicks the output of a tokenizer
      # for the language specified by grammar_abc
      let(:grm_abc_tokens1) do
        pos = Lexical::Position.new(1, 2) # Dummy position
        %w[a a b c c].map { |ch| Lexical::Token.new(ch, ch, pos) }
      end

      # Factory method that builds a sample parse tree.
      # Generated tree has the following structure:
      # S[0,5]
      # +- A[0,5]
      #    +- a[0,1]
      #    +- A[1,4]
      #    |  +- a[1,2]
      #    |  +- A[2,3]
      #    |  |  +- b[2,3]
      #    |  +- c[3,4]
      #    +- c[4,5]
      # Capital letters represent non-terminal nodes
      let(:grm_abc_ptree1) do
        engine = Rley::Engine.new
        engine.use_grammar(grammar_abc)
        parse_result = engine.parse(grm_abc_tokens1)
        ptree = engine.convert(parse_result)
        ptree
      end

      let(:destination) { StringIO.new(+'', 'w') }

      context 'Standard creation & initialization:' do
        it 'should be initialized with an IO argument' do
          expect { Json.new(StringIO.new(+'', 'w')) }.not_to raise_error
        end

        it 'should know its output destination' do
          instance = Json.new(destination)
          expect(instance.output).to eq(destination)
        end
      end # context


      context 'Formatting events:' do
        it 'should render a parse tree in JSON' do
          instance = Json.new(destination)
          visitor = Rley::ParseTreeVisitor.new(grm_abc_ptree1)
          instance.render(visitor)
          expectations = <<-SNIPPET
{
  "root":
    { "S": [
      { "A": [
        {"a": "a"},
        { "A": [
          {"a": "a"},
          { "A": [
            {"b": "b"}
            ]
          },
          {"c": "c"}
          ]
        },
        {"c": "c"}
        ]
      }
      ]
    }
}
    SNIPPET
          expect(destination.string).to eq(expectations.chomp)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
