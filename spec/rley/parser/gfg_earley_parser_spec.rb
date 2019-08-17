# frozen_string_literal: true

require_relative '../../spec_helper'
require 'stringio'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/base/dotted_item'
require_relative '../../../lib/rley/parser/gfg_parsing'

# Load builders and lexers for sample grammars
require_relative '../support/grammar_abc_helper'
require_relative '../support/ambiguous_grammar_helper'
require_relative '../support/grammar_pb_helper'
require_relative '../support/grammar_helper'
require_relative '../support/expectation_helper'

# Load the class under test
require_relative '../../../lib/rley/parser/gfg_earley_parser'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe GFGEarleyParser do
      include GrammarABCHelper # Mix-in module with builder for grammar abc
      include GrammarHelper # Mix-in with method for creating token sequence
      include ExpectationHelper # Mix-in with expectation on parse entry sets

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:grm1_tokens) do
        build_token_sequence(%w[a a b c c], grammar_abc)
      end


      # Grammar 2: A simple arithmetic expression language
      # (based on example in article on Earley's algorithm in Wikipedia)
      # P ::= S.
      # S ::= S "+" M.
      # S ::= M.
      # M ::= M "*" T.
      # M ::= T.
      # T ::= an integer number token.
      # Let's create the grammar piece by piece
      let(:nt_P) { Syntax::NonTerminal.new('P') }
      let(:nt_S) { Syntax::NonTerminal.new('S') }
      let(:nt_M) { Syntax::NonTerminal.new('M') }
      let(:nt_T) { Syntax::NonTerminal.new('T') }
      let(:plus) { Syntax::VerbatimSymbol.new('+') }
      let(:star) { Syntax::VerbatimSymbol.new('*') }
      let(:integer) do
        integer_pattern = /[-+]?[0-9]+/ # Decimal notation
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
        input_sequence = [
          { '2' => 'integer' },
          '+',
          { '3' => 'integer' },
          '*',
          { '4' => 'integer' }
        ]
        return build_token_sequence(input_sequence, grammar_expr)
      end

      # Default instantiation rule
      subject { GFGEarleyParser.new(grammar_abc) }

      context 'Initialization:' do
        it 'should be created with a grammar' do
          expect { GFGEarleyParser.new(grammar_abc) }.not_to raise_error
        end

        it 'should know its grammar' do
          expect(subject.grammar).to eq(grammar_abc)
        end

        it 'should know its dotted items' do
          expect(subject.dotted_items.size).to eq(8)
        end

        it 'should know its flow graph' do
          expect(subject.gf_graph).to be_kind_of(GFG::GrmFlowGraph)
        end
      end # context

      context 'Parsing: ' do
        it 'should parse a valid simple input' do
          parse_result = subject.parse(grm1_tokens)
          expect(parse_result.success?).to eq(true)
          # expect(parse_result.ambiguous?).to eq(false)
          ######################
          # Expectation chart[0]:
          expected = [
            '.S | 0',               # initialization
            'S => . A | 0',         # start rule
            '.A | 0',               # call rule
            'A => . a A c | 0',     # start rule
            'A => . b | 0'          # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)
          expected_terminals(parse_result.chart[0], %w[a b])

          ######################
          # Expectation chart[1]:
          expected = [
            'A => a . A c | 0',     # scan 'a'
            '.A | 1',               # call rule
            'A => . a A c | 1',     # start rule
            'A => . b | 1'          # start rule
          ]
          entry_set_1 = parse_result.chart[1]
          expect(entry_set_1.entries.size).to eq(4)
          compare_entry_texts(entry_set_1, expected)
          expected_terminals(parse_result.chart[1], %w[a b])

          ######################
          # Expectation chart[2]:
          expected = [
            'A => a . A c | 1',     # scan 'a'
            '.A | 2',               # call rule
            'A => . a A c | 2',     # start rule
            'A => . b | 2'          # start rule
          ]
          entry_set_2 = parse_result.chart[2]
          expect(entry_set_2.entries.size).to eq(4)
          compare_entry_texts(entry_set_2, expected)
          expected_terminals(parse_result.chart[2], %w[a b])

          ######################
          # Expectation chart[3]:
          expected = [
            'A => b . | 2',      # scan 'b'
            'A. | 2',            # exit rule
            'A => a A . c | 1'   # end rule
          ]
          entry_set_3 = parse_result.chart[3]
          expect(entry_set_3.entries.size).to eq(3)
          compare_entry_texts(entry_set_3, expected)
          expected_terminals(parse_result.chart[3], ['c'])


          ######################
          # Expectation chart[4]:
          expected = [
            'A => a A c . | 1',   # scan 'c'
            'A. | 1',             # exit rule
            'A => a A . c | 0'    # end rule
          ]
          entry_set_4 = parse_result.chart[4]
          expect(entry_set_4.entries.size).to eq(3)
          compare_entry_texts(entry_set_4, expected)
          expected_terminals(parse_result.chart[4], ['c'])

          ######################
          # Expectation chart[5]:
          expected = [
            'A => a A c . | 0',  # scan 'c'
            'A. | 0',            # exit rule
            'S => A . | 0',      # end rule
            'S. | 0'             # exit rule
          ]
          entry_set_5 = parse_result.chart[5]
          expect(entry_set_5.entries.size).to eq(4)
          compare_entry_texts(entry_set_5, expected)
        end

        it 'should parse a valid simple expression' do
          instance = GFGEarleyParser.new(grammar_expr)
          parse_result = instance.parse(grm2_tokens)
          expect(parse_result.success?).to eq(true)
          # expect(parse_result.ambiguous?).to eq(false)

          ###################### S(0): . 2 + 3 * 4
          # Expectation chart[0]:
          expected = [
            '.P | 0',               # Initialization
            'P => . S | 0',         # start rule
            '.S | 0',               # call rule
            "S => . S '+' M | 0",   # start rule
            'S => . M | 0',         # start rule
            '.M | 0',               # call rule
            "M => . M '*' T | 0",   # start rule
            'M => . T | 0',         # start rule
            '.T | 0',               # call rule
            'T => . integer | 0'    # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)


          ###################### S(1): 2 . + 3 * 4
          # Expectation chart[1]:
          expected = [
            'T => integer . | 0',   # scan '2'
            'T. | 0',               # exit rule
            'M => T . | 0',         # end rule
            'M. | 0',               # exit rule
            'S => M . | 0',         # end rule
            "M => M . '*' T | 0",   # end rule
            'S. | 0',               # exit rule
            'P => S . | 0',         # end rule
            "S => S . '+' M | 0",   # end rule
            'P. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)


          ###################### S(2): 2 + . 3 * 4
          # Expectation chart[2]:
          expected = [
            "S => S '+' . M | 0",   # scan '+'
            '.M | 2',               # call rule
            "M => . M '*' T | 2",   # start rule
            'M => . T | 2',         # start rule
            '.T | 2',               # call rule
            'T => . integer | 2'    # start rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)


          ###################### S(3): 2 + 3 . * 4
          # Expectation chart[3]:
          expected = [
            'T => integer . | 2',   # scan '3'
            'T. | 2',               # exit rule
            'M => T . | 2',         # end rule
            'M. | 2',               # exit rule
            "S => S '+' M . | 0",   # end rule
            "M => M . '*' T | 2",   # end rule
            'S. | 0',               # exit rule
            'P => S . | 0',         # end rule
            "S => S . '+' M | 0",   # end rule
            'P. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)

          ###################### S(4): 2 + 3 * . 4
          # Expectation chart[4]:
          expected = [
            "M => M '*' . T | 2",   # scan '*'
            '.T | 4',               # call rule
            'T => . integer | 4'    # entry rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)

          ###################### S(5): 2 + 3 * 4 .
          # Expectation chart[5]:
          expected = [
            'T => integer . | 4',   # scan '4'
            'T. | 4',               # exit rule
            "M => M '*' T . | 2",   # end rule
            'M. | 2',               # exit rule
            "S => S '+' M . | 0",   # end rule
            "M => M . '*' T | 2",   # end rule
            'S. | 0',               # exit rule
            'P => S . | 0',         # end rule
            "S => S . '+' M | 0",   # end rule
            'P. | 0'                # end rule
          ]
          compare_entry_texts(parse_result.chart[5], expected)
        end

        it 'should parse a nullable grammar' do
          # Simple but problematic grammar for the original Earley parser
          # (based on example in D. Grune, C. Jacobs "Parsing Techniques" book)
          # Ss =>  A A 'x';
          # A => ;
          t_x = Syntax::VerbatimSymbol.new('x')

          builder = Syntax::GrammarBuilder.new
          builder.add_terminals(t_x)
          builder.add_production('Ss' => %w[A A x])
          builder.add_production('A' => [])
          pos = Lexical::Position.new(1, 1)
          tokens = [Lexical::Token.new('x', t_x, pos)]

          instance = GFGEarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          ###################### S(0): . x
          # Expectation chart[0]:
          expected = [
            '.Ss | 0',              # Initialization
            "Ss => . A A 'x' | 0",  # start rule
            '.A | 0',               # call rule
            'A => . | 0',           # start rule
            'A. | 0',               # exit rule
            "Ss => A . A 'x' | 0",  # end rule
            "Ss => A A . 'x' | 0"   # end rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1): x .
          # Expectation chart[1]:
          expected = [
            "Ss => A A 'x' . | 0",  # scan 'x'
            'Ss. | 0'               # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)
        end

        it 'should parse an ambiguous grammar (I)' do
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

          builder = Syntax::GrammarBuilder.new do
            add_terminals(t_int, t_plus, t_star)
            rule 'P' => 'S'
            rule 'S' => %w[S + S]
            rule 'S' => %w[S * S]
            rule 'S' => 'L'
            rule 'L' => 'integer'
          end
          input_sequence = [
            { '2' => 'integer' },
            '+',
            { '3' => 'integer' },
            '*',
            { '4' => 'integer' }
          ]
          tokens = build_token_sequence(input_sequence, builder.grammar)
          instance = GFGEarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          # expect(parse_result.ambiguous?).to eq(true)

          ###################### S(0): . 2 + 3 * 4
          # Expectation chart[0]:
          expected = [
            '.P | 0',             # Initialization
            'P => . S | 0',       # start rule
            '.S | 0',             # call rule
            "S => . S '+' S | 0", # entry rule
            "S => . S '*' S | 0", # entry rule
            'S => . L | 0',       # entry rule
            '.L | 0',             # call rule
            'L => . integer | 0'  # entry rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1): 2 . + 3 * 4
          # Expectation chart[1]:
          expected = [
            'L => integer . | 0', # scan '2'
            'L. | 0',             # exit rule
            'S => L . | 0',       # end rule
            'S. | 0',             # exit rule
            'P => S . | 0',       # end rule
            "S => S . '+' S | 0", # end rule
            "S => S . '*' S | 0", # end rule
            'P. | 0'              # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2): 2 + . 3 * 4
          # Expectation chart[2]:
          expected = [
            "S => S '+' . S | 0", # scan '+'
            '.S | 2',             # call rule
            "S => . S '+' S | 2", # entry rule
            "S => . S '*' S | 2", # entry rule
            'S => . L | 2',       # entry rule
            '.L | 2',             # call rule
            'L => . integer | 2'  # entry rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)

          ###################### S(3): 2 + 3 . * 4
          # Expectation chart[3]:
          expected = [
            'L => integer . | 2', # scan '3'
            'L. | 2',             # exit rule
            'S => L . | 2',       # end rule
            'S. | 2',             # exit rule
            "S => S '+' S . | 0", # end rule
            "S => S . '+' S | 2", # end rule
            "S => S . '*' S | 2", # end rule
            'S. | 0',             # exit rule
            'P => S . | 0',       # end rule
            "S => S . '+' S | 0", # end rule
            "S => S . '*' S | 0", # end rule
            'P. | 0'              # exit rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)

          ###################### S(4): 2 + 3 * . 4
          # Expectation chart[4]:
          expected = [
            "S => S '*' . S | 2", # scan '*'
            "S => S '*' . S | 0", # scan '*'
            '.S | 4',             # call rule
            "S => . S '+' S | 4", # entry rule
            "S => . S '*' S | 4", # entry rule
            'S => . L | 4',       # entry rule
            '.L | 4',             # call rule
            'L => . integer | 4'  # entry rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)

          ###################### S(5): 2 + 3 * 4 .
          # Expectation chart[5]:
          expected = [
            'L => integer . | 4',   # scan '4'
            'L. | 4',               # exit rule
            'S => L . | 4',         # end rule
            'S. | 4',               # exit rule
            "S => S '*' S . | 2",   # end rule
            "S => S '*' S . | 0",   # end rule
            "S => S . '+' S | 4",   # end rule
            "S => S . '*' S | 4",   # end rule
            'S. | 2',               # exit rule
            'S. | 0',               # exit rule
            "S => S '+' S . | 0",   # end rule
            "S => S . '+' S | 2",   # end rule
            "S => S . '*' S | 2",   # end rule
            'P => S . | 0',         # end rule
            "S => S . '+' S | 0",   # end rule
            "S => S . '*' S | 0",   # end rule
            'P. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[5], expected)

          expected_antecedents = {
            'L => integer . | 4' => ['L => . integer | 4'],
            'L. | 4' => ['L => integer . | 4'],
            'S => L . | 4' => ['L. | 4'],
            'S. | 4' => ['S => L . | 4'],
            "S => S '*' S . | 2" => ['S. | 4'],
            "S => S '*' S . | 0" => ['S. | 4'],
            "S => S . '+' S | 4" => ['S. | 4'],
            "S => S . '*' S | 4" => ['S. | 4'],
            'S. | 2' => ["S => S '*' S . | 2"],
            'S. | 0' => ["S => S '*' S . | 0", "S => S '+' S . | 0"],
            "S => S '+' S . | 0" => ['S. | 2'],
            "S => S . '+' S | 2" => ['S. | 2'],
            "S => S . '*' S | 2" => ['S. | 2'],
            'P => S . | 0' => ['S. | 0'],
            "S => S . '+' S | 0" => ['S. | 0'],
            "S => S . '*' S | 0" => ['S. | 0'],
            'P. | 0' => ['P => S . | 0']
          }
          check_antecedence(parse_result, 5, expected_antecedents)
        end

        it 'should parse an ambiguous grammar (II)' do
          extend(AmbiguousGrammarHelper)
          grammar = grammar_builder.grammar
          instance = GFGEarleyParser.new(grammar)
          tokens = tokenize('abc + def + ghi', grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          # expect(parse_result.ambiguous?).to eq(true)

          ###################### S(0): . abc + def + ghi
          # Expectation chart[0]:
          expected = [
            '.S | 0',             # Initialization
            'S => . E | 0',       # start rule
            '.E | 0',             # call rule
            'E => . E + E | 0',   # start rule
            'E => . id | 0'       # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1): abc . + def + ghi
          # Expectation chart[1]:
          expected = [
            'E => id . | 0',      # scan 'abc'
            'E. | 0',             # exit rule
            'S => E . | 0',       # end rule
            'E => E . + E | 0',   # end rule
            'S. | 0'              # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2): abc + . def + ghi
          # Expectation chart[2]:
          expected = [
            'E => E + . E | 0',   # Scan '+'
            '.E | 2',             # call rule
            'E => . E + E | 2',   # entry rule
            'E => . id | 2'       # entry rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)

          ###################### S(3): abc + def .  + ghi
          # Expectation chart[3]:
          expected = [
            'E => id . | 2',      # Scan 'def'
            'E. | 2',             # exit rule
            'E => E + E . | 0',   # end rule
            'E => E . + E | 2',   # end rule
            'E. | 0',             # exit rule
            'S => E . | 0',       # end rule
            'E => E . + E | 0',   # end rule
            'S. | 0'              # exit rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)

          ###################### S(4): abc + def + . ghi
          # Expectation chart[4]:
          expected = [
            'E => E + . E | 2',   # Scan '+'
            'E => E + . E | 0',   # Scan '+'
            '.E | 4',             # call rule
            'E => . E + E | 4',   # start rule
            'E => . id | 4'       # start rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)

          ###################### S(5): abc + def + ghi .
          # Expectation chart[5]:
          expected = [
            'E => id . | 4',      # Scan 'ghi'
            'E. | 4',             # exit rule
            'E => E + E . | 2',   # end rule
            'E => E + E . | 0',   # end rule
            'E => E . + E | 4',   # end rule
            'E. | 2',             # exit rule
            'E. | 0',             # exit rule
            'E => E . + E | 2',   # end rule
            'S => E . | 0',       # end rule
            'E => E . + E | 0',   # end rule
            'S. | 0'              # exit rule
          ]
          compare_entry_texts(parse_result.chart[5], expected)
        end

        it 'should parse an invalid simple input' do
          # Parse an erroneous input (b is missing)
          wrong = build_token_sequence(%w[a a c c], grammar_abc)
          parse_result = subject.parse(wrong)
          expect(parse_result.success?).to eq(false)
          err_msg = <<-MSG
Syntax error at or near token line 1, column 5 >>>c<<<
Expected one of: ['a', 'b'], found a 'c' instead.
MSG
          expect(parse_result.failure_reason.message).to eq(err_msg.chomp)
        end

        it 'should report error when no input provided but was required' do
          helper = GrammarPBHelper.new
          grammar = helper.grammar
          instance = GFGEarleyParser.new(grammar)
          tokens = helper.tokenize('')
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(false)
          err_msg = 'Input cannot be empty.'
          expect(parse_result.failure_reason.message).to eq(err_msg)
        end

        it 'should report error when input ends prematurely' do
          helper = GrammarPBHelper.new
          grammar = helper.grammar
          instance = GFGEarleyParser.new(grammar)
          tokens = helper.tokenize('1 +')
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(false)
          ###################### S(0) == . 1 +
          # Expectation chart[0]:
          expected = [
            '.S | 0',               # initialization
            'S => . E | 0',         # start rule
            '.E | 0',               # call rule
            'E => . int | 0',       # start rule
            'E => . ( E + E ) | 0', # start rule
            'E => . E + E | 0'      # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1) == 1 . +
          # Expectation chart[1]:
          expected = [
            'E => int . | 0',         # scan '1'
            'E. | 0',                 # exit rule
            'S => E . | 0',           # end rule
            'E => E . + E | 0',       # end rule
            'S. | 0'                  # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2) == 1 + .
          # Expectation chart[2]:
          expected = [
            'E => E + . E | 0',       # scan '+'
            '.E | 2',                 # exit rule
            'E => . int | 2',         # start rule
            'E => . ( E + E ) | 2',   # start rule
            'E => . E + E | 2'        # start rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)

          err_msg = +"Premature end of input after '+' at position line 1, "
          err_msg << 'column 3'
          err_msg << "\nExpected one of: ['int', '(']."
          expect(parse_result.failure_reason.message).to eq(err_msg)
        end


        it 'should parse a common sample' do
          # Use grammar based on example found in paper of
          # K. Pingali and G. Bilardi:
          # "A Graphical Model for Context-Free Grammar Parsing"
          helper = GrammarPBHelper.new
          grammar = helper.grammar
          instance = GFGEarleyParser.new(grammar)
          tokens = helper.tokenize('7 + 8 + 9')
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          ###################### S(0) == . 7 + 8 + 9
          # Expectation chart[0]:
          expected = [
            '.S | 0',               # initialization
            'S => . E | 0',         # start rule
            '.E | 0',               # call rule
            'E => . int | 0',       # start rule
            'E => . ( E + E ) | 0', # start rule
            'E => . E + E | 0'      # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1) == 7 . + 8 + 9
          # Expectation chart[1]:
          expected = [
            'E => int . | 0',       # scan '7'
            'E. | 0',               # exit rule
            'S => E . | 0',         # end rule
            'E => E . + E | 0',     # end rule
            'S. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2) == 7 + . 8 + 9
          # Expectation chart[2]:
          expected = [
            'E => E + . E | 0',       # scan '+'
            '.E | 2',                 # exit rule
            'E => . int | 2',         # start rule
            'E => . ( E + E ) | 2',   # start rule
            'E => . E + E | 2'        # start rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)

          ###################### S(3) == 7 + 8 . + 9
          # Expectation chart[3]:
          expected = [
            'E => int . | 2',         # scan '8'
            'E. | 2',                 # exit rule
            'E => E + E . | 0',       # end rule
            'E => E . + E | 2',       # end rule
            'E. | 0',                 # exit rule
            'S => E . | 0',           # end rule
            'E => E . + E | 0',       # end rule
            'S. | 0'                  # exit rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)

          ###################### S(4) == 7 + 8 + . 9
          # Expectation chart[4]:
          expected = [
            'E => E + . E | 2',       # scan '+'
            'E => E + . E | 0',       # scan '+'
            '.E | 4',                 # exit rule
            'E => . int | 4',         # start rule
            'E => . ( E + E ) | 4',   # start rule
            'E => . E + E | 4'        # start rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)

          ###################### S(5) == 7 + 8 + 9 .
          # Expectation chart[5]:
          expected = [
            'E => int . | 4',         # scan '9'
            'E. | 4',                 # exit rule
            'E => E + E . | 2',       # end rule
            'E => E + E . | 0',       # end rule
            'E => E . + E | 4',       # exit rule (not shown in paper)
            'E. | 2',                 # exit rule
            'E. | 0',                 # exit rule
            'E => E . + E | 2',       # end rule
            'S => E . | 0',           # end rule
            'E => E . + E | 0',       # end rule
            'S. | 0'
          ]
          compare_entry_texts(parse_result.chart[5], expected)
        end

        it 'should parse a grammar with nullable nonterminals' do
          # Grammar 4: A grammar with nullable nonterminal
          # based on example from "Parsing Techniques" book
          # (D. Grune, C. Jabobs)
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

          builder = Syntax::GrammarBuilder.new do
            add_terminals(t_a, t_star, t_slash)
            rule 'Z' => 'E'
            rule 'E' => %w[E Q F]
            rule 'E' => 'F'
            rule 'F' => t_a
            rule 'Q' => t_star
            rule 'Q' => t_slash
            rule 'Q' => [] # Empty production
          end

          tokens = build_token_sequence(%w[a a / a], builder.grammar)
          instance = GFGEarleyParser.new(builder.grammar)
          expect { instance.parse(tokens) }.not_to raise_error
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)

          ###################### S(0) == . a a / a
          # Expectation chart[0]:
          expected = [
            '.Z | 0',           # initialization
            'Z => . E | 0',     # start rule
            '.E | 0',           # call rule
            'E => . E Q F | 0', # start rule
            'E => . F | 0',     # start rule
            '.F | 0',           # call rule
            "F => . 'a' | 0"    # start rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1) == a . a / a
          # Expectation chart[1]:
          expected = [
            "F => 'a' . | 0",   # scan 'a'
            'F. | 0',           # exit rule
            'E => F . | 0',     # end rule
            'E. | 0',           # exit rule
            'Z => E . | 0',     # end rule
            'E => E . Q F | 0', # end rule
            'Z. | 0',           # exit rule
            '.Q | 1',           # call rule
            "Q => . '*' | 1",   # start rule
            "Q => . '/' | 1",   # start rule
            'Q => . | 1',       # start rule
            'Q. | 1',           # exit rule
            'E => E Q . F | 0', # end rule
            '.F | 1',           # call rule
            "F => . 'a' | 1"    # start rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2) == a a . / a
          # Expectation chart[2]:
          expected = [
            "F => 'a' . | 1",   # scan 'a'
            'F. | 1',           # exit rule
            'E => E Q F . | 0', # end rule
            'E. | 0',           # exit rule
            'Z => E . | 0',     # end rule
            'E => E . Q F | 0', # end rule
            'Z. | 0',           # exit rule
            '.Q | 2',           # call rule
            "Q => . '*' | 2",   # start rule
            "Q => . '/' | 2",   # start rule
            'Q => . | 2',       # start rule
            'Q. | 2',           # exit rule
            'E => E Q . F | 0', # end rule
            '.F | 2',           # call rule
            "F => . 'a' | 2"    # start rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)


          ###################### S(3) == a a / . a
          # Expectation chart[3]:
          expected = [
            "Q => '/' . | 2",   # scan '/'
            'Q. | 2',           # exit rule
            'E => E Q . F | 0', # end rule
            '.F | 3',           # call rule
            "F => . 'a' | 3"    # entry rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)


          ###################### S(4) == a a / a .
          # Expectation chart[4]:
          expected = [
            "F => 'a' . | 3",   # scan 'a'
            'F. | 3',           # exit rule
            'E => E Q F . | 0', # end rule
            'E. | 0',           # exit rule
            'Z => E . | 0',     # end rule
            'E => E . Q F | 0', # end rule
            'Z. | 0',           # exit rule
            '.Q | 4',           # call rule
            "Q => . '*' | 4",   # start rule
            "Q => . '/' | 4",   # start rule
            'Q => . | 4',       # start rule
            'Q. | 4',           # exit rule
            'E => E Q . F | 0', # end rule
            '.F | 4',           # call rule
            "F => . 'a' | 4"    # entry rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)
        end

        it 'should parse a right recursive grammar' do
          # Simple right recursive grammar
          # based on example in D. Grune, C. Jacobs "Parsing Techniques" book
          # pp. 224 et sq.
          # S =>  a S;
          # S => ;
          # This grammar requires a time that is quadratic in the number of
          # input tokens
          builder = Syntax::GrammarBuilder.new
          builder.add_terminals('a')
          builder.add_production('S' => %w[a S])
          builder.add_production('S' => [])
          grammar = builder.grammar
          tokens = build_token_sequence(%w[a a a a], grammar)

          instance = GFGEarleyParser.new(grammar)
          parse_result = instance.parse(tokens)
          expect(parse_result.success?).to eq(true)
          ###################### S(0): . a a a a
          # Expectation chart[0]:
          expected = [
            '.S | 0',               # Initialization
            'S => . a S | 0',       # start rule
            'S => . | 0',           # start rule
            'S. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[0], expected)

          ###################### S(1): a . a a a
          # Expectation chart[1]:
          expected = [
            'S => a . S | 0',       # scan 'a'
            '.S | 1',               # call rule
            'S => . a S | 1',       # start rule
            'S => . | 1',           # start rule
            'S. | 1',               # exit rule
            'S => a S . | 0'        # end rule
          ]
          compare_entry_texts(parse_result.chart[1], expected)

          ###################### S(2): a a . a a
          # Expectation chart[2]:
          expected = [
            'S => a . S | 1',       # scan 'a'
            '.S | 2',               # call rule
            'S => . a S | 2',       # start rule
            'S => . | 2',           # start rule
            'S. | 2',               # exit rule
            'S => a S . | 1',       # end rule
            'S. | 1',               # exit rule
            'S => a S . | 0',       # end rule
            'S. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[2], expected)

          ###################### S(3): a a a . a
          # Expectation chart[3]:
          expected = [
            'S => a . S | 2',       # scan 'a'
            '.S | 3',               # call rule
            'S => . a S | 3',       # start rule
            'S => . | 3',           # start rule
            'S. | 3',               # exit rule
            'S => a S . | 2',       # end rule
            'S. | 2',               # exit rule
            'S => a S . | 1',       # end rule
            'S. | 1',               # exit rule
            'S => a S . | 0',       # end rule
            'S. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[3], expected)

          ###################### S(4): a a a a .
          # Expectation chart[4]:
          expected = [
            'S => a . S | 3',       # scan 'a'
            '.S | 4',               # call rule
            'S => . a S | 4',       # start rule
            'S => . | 4',           # start rule
            'S. | 4',               # exit rule
            'S => a S . | 3',       # end rule
            'S. | 3',               # exit rule
            'S => a S . | 2',       # end rule
            'S. | 2',               # exit rule
            'S => a S . | 1',       # end rule
            'S. | 1',               # exit rule
            'S => a S . | 0',       # end rule
            'S. | 0'                # exit rule
          ]
          compare_entry_texts(parse_result.chart[4], expected)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
