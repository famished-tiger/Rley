require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/parser/token'
# Load the class under test
require_relative '../../../lib/rley/parser/earley_parser'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe EarleyParser do
=begin
      let(:kw_true) { Syntax::VerbatimSymbol.new('true') }
      let(:kw_false) { Syntax::VerbatimSymbol.new('false') }
      let(:kw_null) { Syntax::VerbatimSymbol.new('null') }
      let(:number) do
        number_pattern = /[-+]?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?/
        Syntax::Literal.new('number', number_pattern)
      end
      let(:string) do
        string_pattern = /"([^\\"]|\\.)*"/
        Syntax::Literal('string', string_pattern)
      end
      let(:lbracket) { Syntax::VerbatimSymbol.new('[') }
      let(:rbracket) { Syntax::VerbatimSymbol.new(']') }
      let(:comma) { Syntax::VerbatimSymbol.new(',') }
      let(:array) { Syntax::NonTerminal.new('Array') }
      let(:object) { Syntax::NonTerminal.new('Object') }

      let(:array_prod) do
        Production.new(array, )
      end
=end

      # Grammar 1: A very simple language
      # S ::= A.
      # A ::= "a" A "c".
      # A ::= "b".
      # Let's create the grammar piece by piece
      let(:nt_S) { Syntax::NonTerminal.new('S') }
      let(:nt_A) { Syntax::NonTerminal.new('A') }
      let(:a_) { Syntax::VerbatimSymbol.new('a') }
      let(:b_)  { Syntax::VerbatimSymbol.new('b') }
      let(:c_)  { Syntax::VerbatimSymbol.new('c') }
      let(:prod_S) { Syntax::Production.new(nt_S, [nt_A]) }
      let(:prod_A1) { Syntax::Production.new(nt_A, [a_, nt_A, c_]) }
      let(:prod_A2) { Syntax::Production.new(nt_A, [b_]) }
      let(:grammar_abc) { Syntax::Grammar.new([prod_S, prod_A1, prod_A2]) }

      # Helper method that mimicks the output of a tokenizer
      # for the language specified by grammar_abc
      def grm1_tokens()
        tokens = [
          Token.new('a', a_),
          Token.new('a', a_),
          Token.new('b', b_),
          Token.new('c', c_),
          Token.new('c', c_)
        ]

        return tokens
      end


      # Grammar 2: A simple arithmetic expression language
      # E ::= S.
      # S ::= S "+" M.
      # S ::= M.
      # M ::= M "*" M.
      # M ::= T.
      # T ::= an integer number token.
      # Let's create the grammar piece by piece
      let(:nt_E) { Syntax::NonTerminal.new('E') }
      let(:nt_M) { Syntax::NonTerminal.new('M') }
      let(:nt_T) { Syntax::NonTerminal.new('T') }
      let(:plus) { Syntax::VerbatimSymbol.new('+') }
      let(:star)  { Syntax::VerbatimSymbol.new('*') }
      let(:integer) do
        integer_pattern = /[-+]?[0-9]+/	# Decimal notation
        Syntax::Literal.new('integer', integer_pattern)
      end
      let(:prod_E) { Syntax::Production.new(nt_E, [nt_S]) }
      let(:prod_S1) { Syntax::Production.new(nt_S, [nt_S, plus, nt_M]) }
      let(:prod_S2) { Syntax::Production.new(nt_S, [nt_M]) }
      let(:prod_M1) { Syntax::Production.new(nt_M, [nt_M, star, nt_M]) }
      let(:prod_M2) { Syntax::Production.new(nt_M, [nt_T]) }
      let(:prod_T) { Syntax::Production.new(nt_T, [integer]) }
      let(:grammar_expr) do
        all_prods = [prod_E, prod_S1, prod_S2, prod_M1, prod_M2, prod_T]
        Syntax::Grammar.new(all_prods)
      end

      # Helper method that mimicks the output of a tokenizer
      # for the language specified by grammar_expr
      def grm2_tokens()
        tokens = [
          Token.new('2', integer),
          Token.new('+', plus),
          Token.new('3', integer),
          Token.new('*', star),
          Token.new('4', integer)
        ]

        return tokens
      end


      # Default instantiation rule
      subject { EarleyParser.new(grammar_abc) }

      context 'Initialization:' do
        it 'should be created with a grammar' do
          expect { EarleyParser.new(grammar_abc) }.not_to raise_error
          expect { EarleyParser.new(grammar_expr) }.not_to raise_error
        end

        it 'should know its grammar' do
          expect(subject.grammar).to eq(grammar_abc)
        end

        it 'should know its dotted items' do
          expect(subject.dotted_items.size).to eq(8)
        end

        it 'should have its start mapping initialized' do
          expect(subject.start_mapping.size).to eq(2)

          start_items_S = subject.start_mapping[nt_S]
          expect(start_items_S.size).to eq(1)
          expect(start_items_S[0].production).to eq(prod_S)

          start_items_A = subject.start_mapping[nt_A]
          expect(start_items_A.size).to eq(2)

          # Assuming that dotted_items are created in same order
          # than production in grammar.
          expect(start_items_A[0].production).to eq(prod_A1)
          expect(start_items_A[1].production).to eq(prod_A2)
        end

        it 'should have its next mapping initialized' do
          expect(subject.next_mapping.size).to eq(5)
        end
      end # context

      context 'Parsing: ' do
        # Helper method. Compare the data from the parse state
        # with values from expectation hash.
        def compare_state(aState, expectations)
          expect(aState.origin).to eq(expectations[:origin])
          dotted_item = aState.dotted_rule
          expect(dotted_item.production).to eq(expectations[:production])
          expect(dotted_item.position).to eq(expectations[:dot])
        end

        # Helper method. Compare the data from all the parse states
        # of a given StateSet with an array of expectation hashes.
        def compare_state_set(aStateSet, expectations)
          (0...expectations.size).each do |i|
            compare_state(aStateSet.states[i], expectations[i])
          end
        end

        it 'should parse a valid simple input' do
          parse_result = subject.parse(grm1_tokens)
          expect(parse_result.success?).to eq(true)

          ######################
          # Expectation chart[0]:
          # S -> . A, 0           # start rule
          # A -> . "a" A "c", 0   # predict from 0
          # A -> . "b", 0         # predict from 0
          expectations = [
            { origin: 0, production: prod_S, dot: 0 },
            { origin: 0, production: prod_A1, dot: 0 },
            { origin: 0, production: prod_A2, dot: 0 }
          ]
          compare_state_set(parse_result.chart[0], expectations)

          ######################
          state_set_1 = parse_result.chart[1]
          expect(state_set_1.states.size).to eq(3)
          # Expectation chart[1]:
          # 0: A -> "a" . A "c", 0   # scan from S(0) 1
          # 1: A -> . "a" A "c", 1   # predict from 0
          # 2: A -> . "b", 1         # predict from 0
          expectations = [
            { origin: 0, production: prod_A1, dot: 1 },
            { origin: 1, production: prod_A1, dot: 0 },
            { origin: 1, production: prod_A2, dot: 0 }
          ]
          compare_state_set(state_set_1, expectations)

          ######################
          state_set_2 = parse_result.chart[2]
          expect(state_set_2.states.size).to eq(3)
          # Expectation chart[2]:
          # 0: A -> "a" . A "c", 1  # scan from S(0) 1
          # 1: A -> . "a" A "c", 2  # predict from 0
          # 2: A -> . "b", 2        # predict from 0
          expectations = [
            { origin: 1, production: prod_A1, dot: 1 },
            { origin: 2, production: prod_A1, dot: 0 },
            { origin: 2, production: prod_A2, dot: 0 }
          ]
          compare_state_set(state_set_2, expectations)

          ######################
          state_set_3 = parse_result.chart[3]
          expect(state_set_3.states.size).to eq(2)
          # Expectation chart[3]:
          # 0: A -> "b" ., 2      # scan from S(2) 2
          # 1: A -> "a" A . "c", 1 # complete from 0 and S(2) 0
          expectations = [
            { origin: 2, production: prod_A2, dot: -1 },
            { origin: 1, production: prod_A1, dot: 2 }
          ]
          compare_state_set(state_set_3, expectations)

          ######################
          state_set_4 = parse_result.chart[4]
          expect(state_set_4.states.size).to eq(2)
          # Expectation chart[4]:
          # 0: A -> "a" A "c" ., 1  # scan from S(3) 1
          # 1: A -> "a" A . "c", 0  # complete from 0 and S(1) 0
          expectations = [
            { origin: 1, production: prod_A1, dot: -1 },
            { origin: 0, production: prod_A1, dot: 2 }
          ]
          compare_state_set(state_set_4, expectations)

          ######################
          state_set_5 = parse_result.chart[5]
          expect(state_set_5.states.size).to eq(2)
          # Expectation chart[5]:
          # 0: A -> "a" A "c" ., 0  # scan from S(4) 1
          # 1: S -> A ., 0  # complete from 0 and S(0) 0
          expectations = [
            { origin: 0, production: prod_A1, dot: -1 },
            { origin: 0, production: prod_S, dot: -1 }
          ]
          compare_state_set(state_set_5, expectations)
        end

        it 'should parse an invalid simple input' do
          # Parse an erroneous input (b is missing)
          wrong = [
            Token.new('a', a_),
            Token.new('a', a_),
            Token.new('c', c_),
            Token.new('c', c_)
          ]
          parse_result = subject.parse(wrong)
          expect(parse_result.success?).to eq(false)

          ###################### S(0) == . a a c c
          # Expectation chart[0]:
          # S -> . A, 0 # start rule
          # A -> . "a" A "c", 0
          # A -> . "b", 0
          expectations = [
            { origin: 0, production: prod_S, dot: 0 },
            { origin: 0, production: prod_A1, dot: 0 },
            { origin: 0, production: prod_A2, dot: 0 }
          ]
          compare_state_set(parse_result.chart[0], expectations)

          ###################### S(1) == a . a c c
          state_set_1 = parse_result.chart[1]
          expect(state_set_1.states.size).to eq(3)
          # Expectation chart[1]:
          # 0: A -> "a" . A "c", 0   # scan from S(0) 1
          # 1: A -> . "a" A "c", 1   # predict from 0
          # 2: A -> . "b", 1         # predict from 0
          expectations = [
            { origin: 0, production: prod_A1, dot: 1 },
            { origin: 1, production: prod_A1, dot: 0 },
            { origin: 1, production: prod_A2, dot: 0 }
          ]
          compare_state_set(state_set_1, expectations)

          ###################### S(2) == a a . c c
          state_set_2 = parse_result.chart[2]
          expect(state_set_2.states.size).to eq(3)
          # Expectation chart[2]:
          # 0: A -> "a" . A "c", 1  # scan from S(0) 1
          # 1: A -> . "a" A "c", 2  # predict from 0
          # 2: A -> . "b", 2        # predict from 0
          expectations = [
            { origin: 1, production: prod_A1, dot: 1 },
            { origin: 2, production: prod_A1, dot: 0 },
            { origin: 2, production: prod_A2, dot: 0 }
          ]
          compare_state_set(state_set_2, expectations)

          ###################### S(3) == a a c? c
          state_set_3 = parse_result.chart[3]
          expect(state_set_3.states).to be_empty  # This is an error symptom
        end
      end # context

    end # describe
  end # module
end # module

# End of file
