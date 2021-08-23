# frozen_string_literal: true

require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/base_grammar_builder'
require_relative '../../../lib/rley/base/dotted_item'
require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/parser/parse_tracer'
require_relative '../../../lib/rley/gfg/grm_flow_graph'
require_relative '../../../lib/rley/base/grm_items_builder'
require_relative '../support/grammar_abc_helper'
require_relative '../support/grammar_b_expr_helper'
require_relative '../support/grammar_helper'


require_relative '../../../lib/rley/parser/gfg_earley_parser'
# Load the class under test
require_relative '../../../lib/rley/parser/gfg_parsing'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe GFGParsing do
      include GrammarABCHelper # Mix-in module with builder for grammar abc
      include GrammarBExprHelper # Mix-in with builder for simple expressions
      include GrammarHelper # Mix-in with method for creating token sequence

      # Helper method. Create an array of dotted items
      # from the given grammar
      def build_items_for_grammar(aGrammar)
        helper = Object.new
        helper.extend(Base::GrmItemsBuilder)
        return helper.build_dotted_items(aGrammar)
      end

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grm1) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:grm1_tokens) { build_token_sequence(%w[a a b c c], grm1) }
      let(:grm1_token_b) { build_token_sequence(['b'], grm1) }

      # Helper method. Create an array of dotted items
      # from the abc grammar
      let(:items_from_grammar) { build_items_for_grammar(grm1) }
      let(:sample_gfg) { GFG::GrmFlowGraph.new(items_from_grammar) }

      let(:output) { StringIO.new('', 'w') }

      # Default instantiation rule
      subject { GFGParsing.new(sample_gfg) }

      context 'Initialization:' do
        it 'should be created with a GFG' do
          expect { GFGParsing.new(sample_gfg) }.not_to raise_error
        end

        it 'should have an empty tokens array' do
          expect(subject.tokens).to be_empty
        end

        it 'should know its chart object' do
          expect(subject.chart).to be_kind_of(GFGChart)
        end

        it 'should know the initial parse entry' do
          expect(subject.initial_entry).to eq(subject.chart.initial_entry)
        end

        it 'should have no antecedence for the initial parse entry' do
          antecedence = subject.antecedence
          expect(antecedence.size).to eq(1)
          expect(antecedence.fetch(subject.initial_entry)).to be_empty
        end

=begin
        it 'should emit trace level 1 info' do
          tracer = ParseTracer.new(1, output, grm1_tokens)
          Parsing.new([ start_dotted_rule ], grm1_tokens, tracer)
          expectations = <<-SNIPPET
['a', 'a', 'b', 'c', 'c']
|. a . a . b . c . c .|
|>   .   .   .   .   .| [0:0] S => . A
SNIPPET
          expect(output.string).to eq(expectations)
        end
=end
      end # context

      context 'Parsing:' do
        # Utility method to fill the first entry set...
        def fill_first_set
          subject.start_rule(subject.initial_entry, 0)
          subject.call_rule(subject.chart[0].last, 0)
          subject.start_rule(subject.chart[0].last, 0)
        end

        # Utility method to initialize the second entry set...
        def seed_second_set
          # Cheating: we change the tokens to scan...
          # Seeding second entry set...
          subject.scan_rule(0, grm1_token_b[0])
        end

        # Utility method used to invoke the private method 'push_entry'
        def push_entry(aParsing, *args)
          aParsing.send(:push_entry, *args)
        end

        it 'should push a parse entry to a given chart entry set' do
          expect(subject.chart.sets[1]).to be_nil
          a_vertex = sample_gfg.find_vertex('A => a . A c')

          push_entry(subject, a_vertex, 1, 1, :scan_rule)
          expect(subject.chart[1].size).to eq(1)
          expect(subject.chart[1].first.vertex).to eq(a_vertex)

          # Pushing twice the same state must be no-op
          push_entry(subject, a_vertex, 1, 1, :scan_rule)
          expect(subject.chart[1].size).to eq(1)

          # Pushing to another entry set
          push_entry(subject, a_vertex, 1, 2, :scan_rule)
          expect(subject.chart[2].size).to eq(1)
        end

        it 'should complain when trying to push nil instead of vertex' do
          err = StandardError
          msg = 'Vertex may not be nil'
          expect { push_entry(subject, nil, 1, 1, :start_rule) }
            .to raise_error(err, msg)
        end

        it 'should use the start rule with initial entry' do
          expect(subject.chart[0].size).to eq(1)
          initial_entry = subject.initial_entry
          subject.start_rule(initial_entry, 0)

          expect(subject.chart[0].size).to eq(2)
          new_entry = subject.chart[0].last
          expect(new_entry.vertex.label).to eq('S => . A')
          expect(subject.antecedence.fetch(new_entry)).to eq([initial_entry])
        end

        it 'should apply the call rule correctly' do
          subject.start_rule(subject.initial_entry, 0)
          # A parse entry with vertex 'S => . A' was added...
          second_entry = subject.chart[0].last
          subject.call_rule(second_entry, 0)

          expect(subject.chart[0].size).to eq(3)
          new_entry = subject.chart[0].last
          expect(new_entry.vertex.label).to eq('.A')
          expect(subject.antecedence.fetch(new_entry)).to eq([second_entry])
        end

        it 'should apply the start rule correctly' do
          subject.start_rule(subject.chart[0].first, 0)
          subject.call_rule(subject.chart[0].last, 0)
          expect(subject.chart[0].size).to eq(3)
          # Last entry is: (.A, 0)
          dot_A_entry = subject.chart[0].last

          subject.start_rule(dot_A_entry, 0)

          # Expectations: two entries:
          expected = ['A => . a A c', 'A => . b']
          expect(subject.chart[0].size).to eq(5)
          expect(subject.chart[0].pop.vertex.label).to eq(expected.last)
          fourth_entry = subject.chart[0].last
          expect(fourth_entry.vertex.label).to eq(expected.first)
          expect(subject.antecedence.fetch(fourth_entry)).to eq([dot_A_entry])
        end

        it 'should apply the scan rule correctly' do
          # Filling manually first entry set...
          fill_first_set
          # There are two entries expecting a terminal:
          # ['A => . a A c', 'A => . b']
          fourth_entry = subject.chart[0].entries[3] # 'A => . a A c'

          expect(subject.chart.sets[1]).to be_nil
          subject.scan_rule(0, grm1_tokens[0])
          # Given that the scanned token is 'a'...
          # Then a new entry is added in next entry set
          expect(subject.chart[1].size).to eq(1)
          last_entry = subject.chart[1].last

          # Entry must be past the terminal symbol
          expect(last_entry.vertex.label).to eq('A => a . A c')
          expect(last_entry.origin).to eq(0)
          antecedence = subject.antecedence
          expect(antecedence.fetch(last_entry)).to eq([fourth_entry])
        end

        it 'should apply the exit rule correctly' do
          # Filling manually first entry set...
          fill_first_set

          # Initial manually first entry set...
          seed_second_set

          # Given that the scanned token is 'b'...
          # Then a new entry is added in next entry set
          expect(subject.chart[1].size).to eq(1)
          last_entry = subject.chart[1].last

          # Entry must be past the terminal symbol
          expect(last_entry.vertex.label).to eq('A => b .')
          expect(last_entry.origin).to eq(0)

          # Apply exit rule...
          subject.exit_rule(last_entry, 1)
          expect(subject.chart[1].size).to eq(2)
          exit_entry = subject.chart[1].last
          expect(exit_entry.vertex.label).to eq('A.')
          expect(exit_entry.origin).to eq(0)
          expect(subject.antecedence.fetch(exit_entry)).to eq([last_entry])
        end

        it 'should apply the end rule correctly' do
          # Filling manually first entry set...
          fill_first_set

          # Initial manually first entry set...
          seed_second_set
          last_entry = subject.chart[1].last

          # Given that the scanned token is 'b'...
          # New entry must be past the terminal symbol
          expect(last_entry.vertex.label).to eq('A => b .')

          # Apply exit rule...
          subject.exit_rule(last_entry, 1)
          expect(subject.chart[1].size).to eq(2)
          exit_entry = subject.chart[1].last
          expect(exit_entry.vertex.label).to eq('A.')

          # ... Now the end rule
          subject.end_rule(subject.chart[1].last, 1)
          expect(subject.chart[1].size).to eq(3)
          end_entry = subject.chart[1].last
          expect(end_entry.vertex.label).to eq('S => A .')
          expect(end_entry.origin).to eq(0)
          expect(subject.antecedence.fetch(end_entry)).to eq([exit_entry])
        end

=begin
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
=end
      end # context

      context 'Provided services:' do
        let(:b_expr_grammar) do
          builder = grammar_expr_builder
          builder.grammar
        end

        def grm_symbol(aSymbolName)
          b_expr_grammar.name2symbol[aSymbolName]
        end

        subject do
          parser = GFGEarleyParser.new(b_expr_grammar)
          tokens = expr_tokenizer('2 + 3 * 4')
          parser.parse(tokens)
        end

        it 'should give a text representation of itself' do
          repr = subject.to_s
          expect(repr).to match(/^success\? true/)

          # Let's test the last chart state only
          expectation = <<REPR
State[5]
  T => integer . | 4
  T. | 4
  M => M * T . | 2
  M. | 2
  S => S + M . | 0
  M => M . * T | 2
  S. | 0
  P => S . | 0
  S => S . + M | 0
  P. | 0
REPR
          expect(expectation).to eq(expectation)
        end
      end # context

      context 'Parse forest building:' do
        let(:b_expr_grammar) do
          builder = grammar_expr_builder
          builder.grammar
        end

        def grm_symbol(aSymbolName)
          b_expr_grammar.name2symbol[aSymbolName]
        end

        subject do
          parser = GFGEarleyParser.new(b_expr_grammar)
          tokens = expr_tokenizer('3 * 4')
          parser.parse(tokens)
        end

        it 'should indicate whether a parse succeeded' do
          expect(subject.success?).to be_truthy
        end
      end # context
    end # describe
  end # module
end # module

# End of file
