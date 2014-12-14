require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/dotted_item'
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
      # (based on example in N. Wirth "Compiler Construction" book, p. 6)
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
      # (based on example in article on Earley's algorithm in Wikipedia)
      # P ::= S.
      # S ::= S "+" M.
      # S ::= M.
      # M ::= M "*" M.
      # M ::= T.
      # T ::= an integer number token.
      # Let's create the grammar piece by piece
      let(:nt_P) { Syntax::NonTerminal.new('P') }
      let(:nt_M) { Syntax::NonTerminal.new('M') }
      let(:nt_T) { Syntax::NonTerminal.new('T') }
      let(:plus) { Syntax::VerbatimSymbol.new('+') }
      let(:star)  { Syntax::VerbatimSymbol.new('*') }
      let(:integer) do
        integer_pattern = /[-+]?[0-9]+/	# Decimal notation
        Syntax::Literal.new('integer', integer_pattern)
      end
      let(:prod_P) { Syntax::Production.new(nt_P, [nt_S]) }
      let(:prod_S1) { Syntax::Production.new(nt_S, [nt_S, plus, nt_M]) }
      let(:prod_S2) { Syntax::Production.new(nt_S, [nt_M]) }
      let(:prod_M1) { Syntax::Production.new(nt_M, [nt_M, star, nt_T]) }
      let(:prod_M2) { Syntax::Production.new(nt_M, [nt_T]) }
      let(:prod_T) { Syntax::Production.new(nt_T, [integer]) }
      let(:grammar_expr) do
        all_prods = [prod_P, prod_S1, prod_S2, prod_M1, prod_M2, prod_T]
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
        # Helper method. Compare the data from all the parse states
        # of a given StateSet with an array of expectation string.
        def compare_state_texts(aStateSet, expectations)
          (0...expectations.size).each do |i|
            expect(aStateSet.states[i].to_s).to eq(expectations[i])
          end
        end

        it 'should parse a valid simple input' do
          parse_result = subject.parse(grm1_tokens)
          expect(parse_result.success?).to eq(true)

          ######################
          # Expectation chart[0]:
          expected = [
            'S => . A | 0',          # start rule
            "A => . 'a' A 'c' | 0",  # predict from 0
            "A => . 'b' | 0"         # predict from 0
          ]
          compare_state_texts(parse_result.chart[0], expected)

          ######################
          # Expectation chart[1]:
          expected = [
            "A => 'a' . A 'c' | 0",   # scan from S(0) 1
            "A => . 'a' A 'c' | 1",   # predict from 0
            "A => . 'b' | 1"          # predict from 0
          ]
          state_set_1 = parse_result.chart[1]
          expect(state_set_1.states.size).to eq(3)
          compare_state_texts(state_set_1, expected)

          ######################
          # Expectation chart[2]:
          expected = [
            "A => 'a' . A 'c' | 1",  # scan from S(0) 1
            "A => . 'a' A 'c' | 2",  # predict from 0
            "A => . 'b' | 2"         # predict from 0
          ]
          state_set_2 = parse_result.chart[2]
          expect(state_set_2.states.size).to eq(3)
          compare_state_texts(state_set_2, expected)

          ######################
          # Expectation chart[3]:
          expected = [
            "A => 'b' . | 2",      # scan from S(2) 2
            "A => 'a' A . 'c' | 1" # complete from 0 and S(2) 0
          ]
          state_set_3 = parse_result.chart[3]
          expect(state_set_3.states.size).to eq(2)
          compare_state_texts(state_set_3, expected)


          ######################
          # Expectation chart[4]:
          expected = [
            "A => 'a' A 'c' . | 1",  # scan from S(3) 1
            "A => 'a' A . 'c' | 0"   # complete from 0 and S(1) 0
          ]
          state_set_4 = parse_result.chart[4]
          expect(state_set_4.states.size).to eq(2)
          compare_state_texts(state_set_4, expected)

          ######################
          # Expectation chart[5]:
          expected = [
            "A => 'a' A 'c' . | 0",  # scan from S(4) 1
            'S => A . | 0'  # complete from 0 and S(0) 0
          ]
          state_set_5 = parse_result.chart[5]
          expect(state_set_5.states.size).to eq(2)
          compare_state_texts(state_set_5, expected)
        end

        it 'should parse a valid simple expression' do
          instance = EarleyParser.new(grammar_expr)
          parse_result = instance.parse(grm2_tokens)
          expect(parse_result.success?).to eq(true)

          ###################### S(0): . 2 + 3 * 4
          # Expectation chart[0]:
          expected = [
            'P => . S | 0',         # start rule
            "S => . S '+' M | 0",   # predict from (1)
            'S => . M | 0',         # predict from (1)
            "M => . M '*' T | 0",   # predict from (3)
            'M => . T | 0',         # predict from (3)
            'T => . integer | 0'    # predict from (3)
          ]
          compare_state_texts(parse_result.chart[0], expected)


          ###################### S(1): 2 . + 3 * 4
          # Expectation chart[1]:
          expected = [
            'T => integer . | 0',   # scan from S(0) 6
            'M => T . | 0',         # complete from (1) and S(0) 5
            'S => M . | 0',         # complete from (2) and S(0) 3
            "M => M . '*' T | 0",   # complete from (2) and S(0) 4
            'P => S . | 0',         # complete from (4) and S(0) 1
            "S => S . '+' M | 0"    # complete from (4) and S(0) 2
          ]
          compare_state_texts(parse_result.chart[1], expected)


          ###################### S(2): 2 + . 3 * 4
          # Expectation chart[2]:
          expected = [
            "S => S '+' . M | 0",   # scan from S(1) 6
            "M => . M '*' T | 2",   # predict from (1)
            'M => . T | 2',         # predict from (1)
            'T => . integer | 2'    # predict from (3)
          ]
          compare_state_texts(parse_result.chart[2], expected)


          ###################### S(3): 2 + 3 . * 4
          # Expectation chart[3]:
          expected = [
            'T => integer . | 2',   # scan from S(2) 4
            'M => T . | 2',         # complete from (1) and S(2) 3
            "S => S '+' M . | 0",   # complete from (1) and S(2) 1
            "M => M . '*' T | 2",   # complete from (2) and S(2) 2
            'P => S . | 0'          # complete from (4) and S(0) 1
          ]
          compare_state_texts(parse_result.chart[3], expected)

          ###################### S(4): 2 + 3 * . 4
          # Expectation chart[4]:
          expected = [
            "M => M '*' . T | 2",   # scan from S(3) 4
            'T => . integer | 4'    # predict from (1)
          ]
          compare_state_texts(parse_result.chart[4], expected)

          ###################### S(5): 2 + 3 * 4 .
          # Expectation chart[5]:
          expected = [
            'T => integer . | 4',    # scan from S(4) 2
            "M => M '*' T . | 2",   # complete from (1) and S(4) 1
            "S => S '+' M . | 0",   # complete from (2) and S(2) 1
            "M => M . '*' T | 2",   # complete from (2) and S(2) 2
            'P => S . | 0'          # complete from (3) and S(2) 2
          ]
          compare_state_texts(parse_result.chart[5], expected)
        end

        it 'should parse a nullable grammar' do
          # Simple but problematic grammar for the original Earley parser
          # (based on example in D. Grune, C. Jacobs "Parsing Techniques" book)
          # Ss =>  A A 'x';
          # A => ;
          t_x = Syntax::VerbatimSymbol.new('x')

          builder = Syntax::GrammarBuilder.new
          builder.add_terminals(t_x)
          builder.add_production('Ss' => %w(A A x))
          builder.add_production('A' => [])
          tokens = [ Token.new('x', t_x) ]

          instance = EarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          ###################### S(0): . x
          # Expectation chart[0]:
          expected = [
            "Ss => . A A 'x' | 0",  # Start rule
            'A => . | 0',           # predict from (1)
            "Ss => A . A 'x' | 0",  # modified predict from (1)
            "Ss => A A . 'x' | 0",  # modified predict from (1)
          ]
          compare_state_texts(parse_result.chart[0], expected)

          ###################### S(1): x .
          # Expectation chart[1]:
          expected = [
            "Ss => A A 'x' . | 0",  # scan from S(0) 4
          ]
          compare_state_texts(parse_result.chart[1], expected)
        end

        it 'should parse an ambiguous grammar' do
          # Grammar 3: A ambiguous arithmetic expression language
          # (based on example in article on Earley's algorithm in Wikipedia)
          # P => S.
          # S => S "+" S.
          # S => S "*" S.
          # S => L.
          # L => an integer number token.
          t_int = Syntax::Literal.new('integer', /[-+]?\d+/)
          t_plus = Syntax::VerbatimSymbol.new('+')
          t_star = Syntax::VerbatimSymbol.new('*')

          builder = Syntax::GrammarBuilder.new
          builder.add_terminals(t_int, t_plus, t_star)
          builder.add_production('P' => 'S')
          builder.add_production('S' => %w(S + S))
          builder.add_production('S' => %w(S * S))
          builder.add_production('S' => 'L')
          builder.add_production('L' => 'integer')
          tokens = [
            Token.new('2', t_int),
            Token.new('+', t_plus),
            Token.new('3', t_int),
            Token.new('*', t_star),
            Token.new('4', t_int)
          ]
          instance = EarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)

          ###################### S(0): . 2 + 3 * 4
          # Expectation chart[0]:
          expected = [
            'P => . S | 0',       # Start rule
            "S => . S '+' S | 0", # predict from (1)
            "S => . S '*' S | 0", # predict from (1)
            'S => . L | 0',       # predict from (1)
            'L => . integer | 0'  # predict from (4)
          ]
          compare_state_texts(parse_result.chart[0], expected)

          ###################### S(1): 2 . + 3 * 4
          # Expectation chart[1]:
          expected = [
            'L => integer . | 0',  # scan from S(0) 4
            'S => L . | 0',       # complete from (1) and S(0) 4
            'P => S . | 0',       # complete from (2) and S(0) 1
            "S => S . '+' S | 0", # complete from (2) and S(0) 2
            "S => S . '*' S | 0", # complete from (2) and S(0) 3
          ]
          compare_state_texts(parse_result.chart[1], expected)

          ###################### S(2): 2 + . 3 * 4
          # Expectation chart[2]:
          expected = [
            "S => S '+' . S | 0", # scan from S(1) 4
            "S => . S '+' S | 2", # predict from (1)
            "S => . S '*' S | 2", # predict from (1)
            'S => . L | 2',       # predict from (1)
            'L => . integer | 2'  # predict from (4)
          ]
          compare_state_texts(parse_result.chart[2], expected)

          ###################### S(3): 2 + 3 . * 4
          # Expectation chart[3]:
          expected = [
            'L => integer . | 2', # scan from S(2) 5
            'S => L . | 2',       # complete from (1) and S(2) 4
            "S => S '+' S . | 0",  # complete from (2) and S(2) 1
            "S => S . '+' S | 2", # complete from (2) and S(2) 2
            "S => S . '*' S | 2", # complete from (2) and S(2) 3
            'P => S . | 0',       # complete from (2) and S(0) 1
            "S => S . '+' S | 0", # complete from (2) and S(0) 2
            "S => S . '*' S | 0", # complete from (2) and S(0) 3
          ]
          compare_state_texts(parse_result.chart[3], expected)

          ###################### S(4): 2 + 3 * . 4
          # Expectation chart[4]:
          expected = [
            "S => S '*' . S | 2", # scan from S(3) 5
            "S => S '*' . S | 0", # scan from S(3) 8
            "S => . S '+' S | 4", # predict from (1)
            "S => . S '*' S | 4", # predict from (1)
            'S => . L | 4',       # predict from (1)
            'L => . integer | 4'  # predict from (4)
          ]
          compare_state_texts(parse_result.chart[4], expected)

          ###################### S(5): 2 + 3 * 4 .
          # Expectation chart[5]:
          expected = [
            'L => integer . | 4',   # scan from S(4) 6
            'S => L . | 4',         # complete from (1) and S(4) 5
            "S => S '*' S . | 2",   # complete from (2) and S(4) 1
            "S => S '*' S . | 0",   # complete from (2) and S(4) 2
            "S => S . '+' S | 4",   # complete from (2) and S(4) 3
            "S => S . '*' S | 4",   # complete from (2) and S(4) 4
            "S => S '+' S . | 0",   # complete from (2) and S(2) 1
            "S => S . '+' S | 2",   # complete from (2) and S(2) 2
            "S => S . '*' S | 2",   # complete from (2) and S(2) 3
            'P => S . | 0',         # complete from (2) and S(0) 1
            "S => S . '+' S | 0",   # complete from (2) and S(0) 2
            "S => S . '*' S | 0"    # complete from (2) and S(0) 3
          ]
          compare_state_texts(parse_result.chart[5], expected)
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
          expected = [
            'S => . A | 0',          # start rule
            "A => . 'a' A 'c' | 0",  # predict from 0
            "A => . 'b' | 0"         # predict from 0
          ]
          compare_state_texts(parse_result.chart[0], expected)

          ###################### S(1) == a . a c c
          expected = [
            "A => 'a' . A 'c' | 0",   # scan from S(0) 1
            "A => . 'a' A 'c' | 1",   # predict from 0
            "A => . 'b' | 1"          # predict from 0
          ]
          compare_state_texts(parse_result.chart[1], expected)

          ###################### S(2) == a a . c c
          expected = [
            "A => 'a' . A 'c' | 1",  # scan from S(0) 1
            "A => . 'a' A 'c' | 2",  # predict from 0
            "A => . 'b' | 2"         # predict from 0
          ]
          compare_state_texts(parse_result.chart[2], expected)


          ###################### S(3) == a a c? c
          state_set_3 = parse_result.chart[3]
          expect(state_set_3.states).to be_empty  # This is an error symptom
        end

        it 'should parse a grammar with nullable nonterminals' do
          # Grammar 4: A grammar with nullable nonterminal
          # based on example in "Parsing Techniques" book (D. Grune, C. Jabobs)
          # Z ::= E.
          # E ::= E Q F.
          # E ::= F.
          # F ::= a.
          # Q ::= *.
          # Q ::= /.
          # Q ::=.
          t_a = Syntax::VerbatimSymbol.new('a')
          t_star = Syntax::VerbatimSymbol.new('*')
          t_slash = Syntax::VerbatimSymbol.new('/')

          builder = Syntax::GrammarBuilder.new
          builder.add_terminals(t_a, t_star, t_slash)
          builder.add_production('Z' => 'E')
          builder.add_production('E' => %w(E Q F))
          builder.add_production('E' => 'F')
          builder.add_production('F' => t_a)
          builder.add_production('Q' => t_star)
          builder.add_production('Q' => t_slash)
          builder.add_production('Q' => []) # Empty production
          tokens = [
            Token.new('a', t_a),
            Token.new('a', t_a),
            Token.new('/', t_slash),
            Token.new('a', t_a)
          ]

          instance = EarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)

          ###################### S(0) == . a a / a
          # Expectation chart[0]:
          expected = [
            'Z => . E | 0',     # start rule
            'E => . E Q F | 0', # predict from (1)
            'E => . F | 0',     # predict from (1)
            "F => . 'a' | 0"    # predict from (3)
          ]
          compare_state_texts(parse_result.chart[0], expected)

          ###################### S(1) == a . a / a
          # Expectation chart[1]:
          expected = [
            "F => 'a' . | 0", # scan from S(0) 4
            'E => F . | 0',   # complete from (1) and S(0) 3
            'Z => E . | 0',   # complete from (2) and S(0) 1
            'E => E . Q F | 0',  # complete from (2) and S(0) 2
            "Q => . '*' | 1",  # Predict from (4)
            "Q => . '/' | 1",  # Predict from (4)
            'Q => . | 1',      # Predict from (4)
            'E => E Q . F | 0',  # Modified predict from (4)
            "F => . 'a' | 1"   # Predict from (8)
          ]
          compare_state_texts(parse_result.chart[1], expected)

          ###################### S(2) == a a . / a
          # Expectation chart[2]:
          expected = [
            "F => 'a' . | 1", # scan from S(1) 9
            'E => E Q F . | 0',  # complete from (1) and S(1) 8
            'Z => E . | 0',      # complete from (1) and S(0) 1
            'E => E . Q F | 0',  # complete from (1) and S(0) 2
            "Q => . '*' | 2",    # Predict from (4)
            "Q => . '/' | 2",    # Predict from (4)
            'Q => . | 2',        # Predict from (4)
            'E => E Q . F | 0',  # Complete from (5) and S(1) 4
            "F => . 'a' | 2"     # Predict from (8)
          ]
          compare_state_texts(parse_result.chart[2], expected)


          ###################### S(3) == a a / . a
          # Expectation chart[3]:
          expected = [
            "Q => '/' . | 2",    # scan from S(2) 6
            'E => E Q . F | 0',  # complete from (1) and S(1) 4
            "F => . 'a' | 3"     # Predict from (2)
          ]
          compare_state_texts(parse_result.chart[3], expected)


          ###################### S(4) == a a / a .
          # Expectation chart[4]:
          expected = [
            "F => 'a' . | 3",    # scan from S(3) 3
            'E => E Q F . | 0',  # complete from (1) and S(3) 2
            'Z => E . | 0',      # complete from (2) and S(0) 1
            'E => E . Q F | 0',  # complete from (2) and S(0) 2
            "Q => . '*' | 4",    # Predict from (4)
            "Q => . '/' | 4",    # Predict from (4)
            'Q => . | 4',        # Predict from (4)
            'E => E Q . F | 0',  # Modified predict from (4)
            "F => . 'a' | 4"     # Predict from (8)
          ]
          compare_state_texts(parse_result.chart[4], expected)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
