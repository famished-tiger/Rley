require_relative '../../spec_helper'
require 'stringio'

require_relative '../support/grammar_abc_helper'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/earley_parser'
require_relative '../../../lib/rley/ptree/parse_tree'
require_relative '../../../lib/rley/parse_tree_visitor'
# Load the class under test
require_relative '../../../lib/rley/formatter/json'

module Rley # Re-open the module to get rid of qualified names
  module Formatter
    describe Json do
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      # Variables for the terminal symbols
      let(:a_) { grammar_abc.name2symbol['a'] }
      let(:b_) { grammar_abc.name2symbol['b'] }
      let(:c_) { grammar_abc.name2symbol['c'] }

      # Helper method that mimicks the output of a tokenizer
      # for the language specified by gramma_abc
      let(:grm_abc_tokens1) do
        [
          Parser::Token.new('a', a_),
          Parser::Token.new('a', a_),
          Parser::Token.new('b', b_),
          Parser::Token.new('c', c_),
          Parser::Token.new('c', c_)
        ]
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
        parser = Parser::EarleyParser.new(grammar_abc)
        parse_result = parser.parse(grm_abc_tokens1)
        parse_result.parse_tree
      end

      let(:destination) { StringIO.new('', 'w') }

      context 'Standard creation & initialization:' do
        it 'should be initialized with an IO argument' do
          expect { Json.new(StringIO.new('', 'w')) }.not_to raise_error
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
