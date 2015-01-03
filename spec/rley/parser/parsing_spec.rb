require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/earley_parser'
require_relative '../support/grammar_abc_helper'
require_relative '../support/grammar_b_expr_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/parsing'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe Parsing do
      include GrammarABCHelper  # Mix-in module with builder for grammar abc
      include GrammarBExprHelper # Mix-in with builder for simple expressions

      # Grammar 1: A very simple language
      # S ::= A.
      # A ::= "a" A "c".
      # A ::= "b".
      let(:nt_S) { Syntax::NonTerminal.new('S') }
      let(:nt_A) { Syntax::NonTerminal.new('A') }
      let(:a_) { Syntax::VerbatimSymbol.new('a') }
      let(:b_)  { Syntax::VerbatimSymbol.new('b') }
      let(:c_)  { Syntax::VerbatimSymbol.new('c') }
      let(:prod_S) { Syntax::Production.new(nt_S, [nt_A]) }
      let(:prod_A1) { Syntax::Production.new(nt_A, [a_, nt_A, c_]) }
      let(:prod_A2) { Syntax::Production.new(nt_A, [b_]) }


      # Helper method that mimicks the output of a tokenizer
      # for the language specified by gramma_abc
      let(:grm1_tokens) do
        [
          Token.new('a', a_),
          Token.new('a', a_),
          Token.new('b', b_),
          Token.new('c', c_),
          Token.new('c', c_)
        ]
      end


      let(:start_dotted_rule) { DottedItem.new(prod_S, 0) }

      # Default instantiation rule
      subject { Parsing.new(start_dotted_rule, grm1_tokens) }

      context 'Initialization:' do
        it 'should be created with list of tokens and start dotted rule' do
          start_rule = start_dotted_rule
          tokens = grm1_tokens
          expect { Parsing.new(start_rule, tokens) }.not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(grm1_tokens)
        end

        it 'should know its chart object' do
          expect(subject.chart).to be_kind_of(Chart)
        end
      end # context

      context 'Parsing:' do
        it 'should push a state to a given chart entry' do
          expect(subject.chart[1]).to be_empty
          item = DottedItem.new(prod_A1, 1)

          subject.push_state(item, 1, 1)
          expect(subject.chart[1]).not_to be_empty
          expect(subject.chart[1].first.dotted_rule).to eq(item)

          # Pushing twice the same state must be no-op
          subject.push_state(item, 1, 1)
          expect(subject.chart[1].size).to eq(1)
        end

        it 'should complain when trying to push a nil dotted item' do
          err = StandardError
          msg = 'Dotted item may not be nil'
          expect { subject.push_state(nil, 1, 1) }.to raise_error(err, msg)
        end


        it 'should retrieve the parse states that expect a given terminal' do
          item1 = DottedItem.new(prod_A1, 2)
          item2 = DottedItem.new(prod_A1, 1)
          subject.push_state(item1, 2, 2)
          subject.push_state(item2, 2, 2)
          states = subject.states_expecting(c_, 2, false)
          expect(states.size).to eq(1)
          expect(states[0].dotted_rule).to eq(item1)
        end

        it 'should update the states upon token match' do
          # When a input token matches an expected terminal symbol
          # then new parse states must be pushed to the following chart slot
          expect(subject.chart[1]).to be_empty

          item1 = DottedItem.new(prod_A1, 0)
          item2 = DottedItem.new(prod_A2, 0)
          subject.push_state(item1, 0, 0)
          subject.push_state(item2, 0, 0)
          subject.scanning(a_, 0) { |i| i } # Code block is mock

          # Expected side effect: a new state at chart[1]
          expect(subject.chart[1].size).to eq(1)
          new_state = subject.chart[1].states[0]
          expect(new_state.dotted_rule).to eq(item1)
          expect(new_state.origin).to eq(0)
        end
      end # context

      context 'Parse tree building:' do
        let(:sample_grammar1) do
          builder = grammar_abc_builder
          builder.grammar
        end

        let(:token_seq1) do
          %w(a a b c c).map do |letter|
            Token.new(letter, sample_grammar1.name2symbol[letter])
          end
        end

        let(:b_expr_grammar) do
          builder = grammar_expr_builder
          builder.grammar
        end

        def grm_symbol(aSymbolName)
          b_expr_grammar.name2symbol[aSymbolName]
        end


        it 'should build the parse tree for a simple non-ambiguous grammar' do
          parser = EarleyParser.new(sample_grammar1)
          instance = parser.parse(token_seq1)
          ptree = instance.parse_tree
          expect(ptree).to be_kind_of(PTree::ParseTree)
        end

        it 'should build the parse tree for a simple expression grammar' do
          parser = EarleyParser.new(b_expr_grammar)
          tokens = expr_tokenizer('2 + 3 * 4', b_expr_grammar)
          instance = parser.parse(tokens)
          ptree = instance.parse_tree
          expect(ptree).to be_kind_of(PTree::ParseTree)

          # Expect parse tree:
          # P[0, 5]
          # +- S[0, 5]
          #    +- S[0, 1]
          #       +- M[0, 1]
          #          +- T[0, 1]
          #          +- integer(2)[0, 1]
          #    +- +[?, ?]
          #    +- M[2, 5]
          expect(ptree.root.symbol). to eq(grm_symbol('P'))
          expect(ptree.root.range). to eq([0, 5])
          expect(ptree.root.children.size). to eq(1)

          node = ptree.root.children[0] # S
          expect(node.symbol). to eq(grm_symbol('S'))
          expect(node.range). to eq([0, 5])
          expect(node.children.size). to eq(3)

          (node_s, node_plus, node_m) = node.children
          expect(node_s.symbol).to eq(grm_symbol('S'))
          expect(node_s.range).to eq(low: 0, high: 1)
          expect(node_s.children.size).to eq(1)
          expect(node_plus.symbol).to eq(grm_symbol('+'))
          expect(node_plus.range).to eq(low: 0, high: 1)  # TODO: fix this
          expect(node_plus.token.lexeme). to eq('+')
          expect(node_m.symbol).to eq(grm_symbol('M'))
          expect(node_m.range).to eq(low: 2, high: 5)
          expect(node_m.children.size).to eq(3)
          
          node = node_s.children[0] # M
          expect(node.symbol).to eq(grm_symbol('M'))
          expect(node.range).to eq([0, 1])
          expect(node.children.size).to eq(1)
          
          node = node.children[0] # T
          expect(node.symbol).to eq(grm_symbol('T'))
          expect(node.range).to eq([0, 1])
          expect(node.children.size).to eq(1)
          
          node = node.children[0] # integer(2)
          expect(node.symbol).to eq(grm_symbol('integer'))
          expect(node.range).to eq([0, 1])
          expect(node.token.lexeme).to eq('2')
          
          (node_m2, node_star, node_t3) = node_m.children
          expect(node_m2.symbol).to eq(grm_symbol('M'))
          expect(node_m2.range).to eq([2, 3])
          expect(node_m2.children.size).to eq(1)
          
          node_t2 = node_m2.children[0] # T
          expect(node_t2.symbol).to eq(grm_symbol('T'))
          expect(node_t2.range).to eq([2, 3])
          expect(node_t2.children.size).to eq(1)
          
          node = node_t2.children[0] # integer(3)
          expect(node.symbol).to eq(grm_symbol('integer'))
          expect(node.range).to eq([2, 3])
          expect(node.token.lexeme).to eq('3')
          
          expect(node_star.symbol).to eq(grm_symbol('*'))
          expect(node_star.range).to eq([2, 3])  # Fix this
          expect(node_star.token.lexeme). to eq('*')
          
          expect(node_t3.symbol).to eq(grm_symbol('T'))
          expect(node_t3.range).to eq([4, 5])
          expect(node_t3.children.size).to eq(1)
          
          node = node_t3.children[0] # integer(4)
          expect(node.symbol).to eq(grm_symbol('integer'))
          expect(node.range).to eq([4, 5])
          expect(node.token.lexeme).to eq('4')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
