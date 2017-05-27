require_relative '../../spec_helper'
require 'stringio'

require_relative '../support/grammar_abc_helper'
require_relative '../../../lib/rley/tokens/token'
require_relative '../../../lib/rley/parser/gfg_earley_parser'
require_relative '../../../lib/rley/ptree/parse_tree'
require_relative '../../../lib/rley/parse_tree_visitor'
# Load the class under test
require_relative '../../../lib/rley/formatter/bracket_notation'

module Rley # Re-open the module to get rid of qualified names
  module Formatter
    describe BracketNotation do
      include GrammarABCHelper # Mix-in module for grammar abc

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
          Tokens::Token.new('a', a_),
          Tokens::Token.new('a', a_),
          Tokens::Token.new('b', b_),
          Tokens::Token.new('c', c_),
          Tokens::Token.new('c', c_)
        ]
      end

      # Factory method that builds a sample parse tree.
      # Generated tree has the following structure:
      # S[0,5]
      # +- A[0,5]
      #    +- a[0,0]
      #    +- A[1,4]
      #    |  +- a[1,1]
      #    |  +- A[2,3]
      #    |  |  +- b[2,3]
      #    |  +- c[3,4]
      #    +- c[4,5]
      # Capital letters represent non-terminal nodes
      let(:grm_abc_ptree1) do
        parser = Parser::GFGEarleyParser.new(grammar_abc)
        parse_result = parser.parse(grm_abc_tokens1)
        parse_result.parse_tree
      end
  
      let(:destination) { StringIO.new('', 'w') }
      subject { BracketNotation.new(destination) }

      context 'Standard creation & initialization:' do
        it 'should be initialized with an IO argument' do
          expect do 
            BracketNotation.new(StringIO.new('', 'w')) 
          end.not_to raise_error
        end
        
        it 'should know its output destination' do
          expect(subject.output).to eq(destination)
        end
      end # context
  

      context 'Formatting events:' do   
        it 'should support visit events of a parse tree' do
          visitor = Rley::ParseTreeVisitor.new(grm_abc_ptree1)
          subject.render(visitor)
          expectations = '[S [A [a a][A [a a][A [b b]][c c]][c c]]]'
          expect(destination.string).to eq(expectations)
        end
        
        it 'should escape square brackets' do
          f_node = double('fake-node')
          f_token = double('fake-token')
          expect(f_node).to receive(:token).and_return(f_token)
          expect(f_token).to receive(:lexeme).and_return('[][]')
          
          subject.after_terminal(f_node)
          expectations = '\[\]\[\]]'
          expect(destination.string).to eq(expectations)          
        end
      end # context
    end # describe
  end # module
end # module

# End of file
