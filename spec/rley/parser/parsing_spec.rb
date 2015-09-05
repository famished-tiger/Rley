require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/parse_tracer'
require_relative '../../../lib/rley/parser/earley_parser'
require_relative '../support/grammar_abc_helper'
require_relative '../support/grammar_b_expr_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/parsing'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe Parsing do
      include GrammarABCHelper # Mix-in module with builder for grammar abc
      include GrammarBExprHelper # Mix-in with builder for simple expressions

      # Grammar 1: A very simple language
      # S => A.
      # A => "a" A "c".
      # A => "b".
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
      let(:output) { StringIO.new('', 'w') }
      let(:sample_tracer) { ParseTracer.new(0, output, grm1_tokens) }

      # Default instantiation rule
      subject { Parsing.new(start_dotted_rule, grm1_tokens, sample_tracer) }

      context 'Initialization:' do
        it 'should be created with list of tokens, start dotted rule, trace' do
          start_rule = start_dotted_rule
          tokens = grm1_tokens
          tracer = sample_tracer
          expect { Parsing.new(start_rule, tokens, tracer) }.not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(grm1_tokens)
        end

        it 'should know its chart object' do
          expect(subject.chart).to be_kind_of(Chart)
        end

        it 'should emit trace level 1 info' do
          tracer = ParseTracer.new(1, output, grm1_tokens)
          Parsing.new(start_dotted_rule, grm1_tokens, tracer)
          expectations = <<-SNIPPET
['a', 'a', 'b', 'c', 'c']
|. a . a . b . c . c .|
|>   .   .   .   .   .| [0:0] S => . A
SNIPPET
          expect(output.string).to eq(expectations)
        end
      end # context

      context 'Parsing:' do
        it 'should push a state to a given chart entry' do
          expect(subject.chart[1]).to be_empty
          item = DottedItem.new(prod_A1, 1)

          subject.push_state(item, 1, 1, :scanning)
          expect(subject.chart[1]).not_to be_empty
          expect(subject.chart[1].first.dotted_rule).to eq(item)

          # Pushing twice the same state must be no-op
          subject.push_state(item, 1, 1, :scanning)
          expect(subject.chart[1].size).to eq(1)
        end

        it 'should complain when trying to push a nil dotted item' do
          err = StandardError
          msg = 'Dotted item may not be nil'
          expect { subject.push_state(nil, 1, 1, :prediction) }
            .to raise_error(err, msg)
        end


        it 'should retrieve the parse states that expect a given terminal' do
          item1 = DottedItem.new(prod_A1, 2)
          item2 = DottedItem.new(prod_A1, 1)
          subject.push_state(item1, 2, 2, :scanning)
          subject.push_state(item2, 2, 2, :scanning)
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
          subject.push_state(item1, 0, 0, :completion)
          subject.push_state(item2, 0, 0, :completion)
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

        subject do
          parser = EarleyParser.new(b_expr_grammar)
          tokens = expr_tokenizer('2 + 3 * 4', b_expr_grammar)
          parser.parse(tokens)
        end

        # Helper. Build a state tracker and a parse tree builder.
        def prepare_parse_tree(aParsing)
          # Accessing private methods by sending message
          state_tracker = aParsing.send(:new_state_tracker)
          builder = aParsing.send(:tree_builder, state_tracker.state_set_index)
          return [state_tracker, builder]
        end


        it 'should create the root of a parse tree' do
          (state_tracker, builder) = prepare_parse_tree(subject)
          # The root node should correspond to the start symbol and
          # its direct children should correspond to rhs of start production
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)

          expect(state_tracker.state_set_index).to eq(subject.tokens.size)
          expected_state = 'P => S . | 0'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(builder.current_node.to_string(0)).to eq('S[0, 5]')
        end

        it 'should use a reduce item for a matched non-terminal' do
          # Setup
          (state_tracker, builder) = prepare_parse_tree(subject)
          # Same state as in previous example

          # Given matched symbol is S[0, 5]
          # And its reduce item is S => S + M . | 0
          # Then add child nodes corresponding to the rhs symbols
          # And make M[?, 5] the current symbol
          subject.insert_matched_symbol(state_tracker, builder)
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[?, 5]
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_state = 'S => S + M . | 0'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(5)
          expect(builder.current_node.to_string(0)).to eq('M[?, 5]')

          # Second similar test

          # Given matched symbol is M[?, 5]
          # And its reduce item is M => M * T . | 2
          # Then add child nodes corresponding to the rhs symbols
          # And make T[?, 5] the current symbol
          subject.insert_matched_symbol(state_tracker, builder)
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[2, 5]
      +- M[2, ?]
      +- *[?, ?]: '(nil)'
      +- T[?, 5]
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_state = 'M => M * T . | 2'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(5)
          expect(builder.current_node.to_string(0)).to eq('T[?, 5]')
        end



        it 'should use a previous item for a terminal symbol' do
          # Setup
          (state_tracker, builder) = prepare_parse_tree(subject)
          3.times do
            subject.insert_matched_symbol(state_tracker, builder)
          end

          # Given matched symbol is T[?, 5]
          # And its reduce item is T => integer . | 4
          # Then add child node corresponding to the rhs symbol
          # And make integer[4, 5]: '(nil)' the current symbol
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[2, 5]
      +- M[2, ?]
      +- *[?, ?]: '(nil)'
      +- T[4, 5]
         +- integer[4, 5]: '(nil)'
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_state = 'T => integer . | 4'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(5)
          integer_repr = "integer[4, 5]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(integer_repr)

          # Given current tree symbol is integer[4, 5]: '(nil)'
          # And its previous item is T => . integer | 4
          # Then attach the token to the terminal node
          # And decrement the state index by one
          # Make *[?, ?]: '(nil)' the current symbol
          subject.insert_matched_symbol(state_tracker, builder)
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[2, 5]
      +- M[2, ?]
      +- *[?, ?]: '(nil)'
      +- T[4, 5]
         +- integer[4, 5]: '4'
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_state = 'T => . integer | 4'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(4)
          next_symbol = "*[?, ?]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(next_symbol)
        end

        it 'should handle [no symbol before dot, terminal tree node] case' do
          # Setup
          (state_tracker, builder) = prepare_parse_tree(subject)
          4.times do
            subject.insert_matched_symbol(state_tracker, builder)
          end

          # Given current tree symbol is *[?, ?]: '(nil)'
          # And current dotted item is T => . integer | 4
          # When one retrieves the parse state expecting the T
          # Then new parse state is changed to: M => M * . T | 2
          subject.insert_matched_symbol(state_tracker, builder)

          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[2, 5]
      +- M[2, ?]
      +- *[?, ?]: '(nil)'
      +- T[4, 5]
         +- integer[4, 5]: '4'
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_state = 'M => M * . T | 2'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(4)
          next_symbol = "*[?, ?]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(next_symbol)

          subject.insert_matched_symbol(state_tracker, builder)
          next_symbol = 'M[2, ?]'
          expect(builder.current_node.to_string(0)).to eq(next_symbol)
        end

        it 'should handle the end of parse tree generation' do
          # Begin setup
          is_done = false
          (state_tracker, builder) = prepare_parse_tree(subject)
          16.times do
            is_done = subject.insert_matched_symbol(state_tracker, builder)
          end

          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, 1]
      +- M[0, 1]
         +- T[0, 1]
            +- integer[0, 1]: '2'
   +- +[1, 2]: '+'
   +- M[2, 5]
      +- M[2, 3]
         +- T[2, 3]
            +- integer[2, 3]: '3'
      +- *[3, 4]: '*'
      +- T[4, 5]
         +- integer[4, 5]: '4'
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)

          expected_state = 'T => . integer | 0'
          expect(state_tracker.parse_state.to_s).to eq(expected_state)
          expect(state_tracker.state_set_index).to eq(0)
          expect(is_done).to eq(true)
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
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, 1]
      +- M[0, 1]
         +- T[0, 1]
            +- integer[0, 1]: '2'
   +- +[1, 2]: '+'
   +- M[2, 5]
      +- M[2, 3]
         +- T[2, 3]
            +- integer[2, 3]: '3'
      +- *[3, 4]: '*'
      +- T[4, 5]
         +- integer[4, 5]: '4'
SNIPPET
          actual = ptree.root.to_string(0)
          expect(actual).to eq(expected_text.chomp)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
