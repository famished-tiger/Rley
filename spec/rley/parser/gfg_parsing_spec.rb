require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/non_terminal'
require_relative '../../../lib/rley/syntax/verbatim_symbol'
require_relative '../../../lib/rley/syntax/production'
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/dotted_item'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/parse_tracer'
require_relative '../../../lib/rley/gfg/grm_flow_graph'
require_relative '../../../lib/rley/parser/grm_items_builder'
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
        helper.extend(Parser::GrmItemsBuilder)
        return helper.build_dotted_items(aGrammar)
      end

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grm1) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:grm1_tokens) do
        build_token_sequence(%w(a a b c c), grm1)
      end

      let(:grm1_token_b) { build_token_sequence(%w(b), grm1) }

      # Helper method. Create an array of dotted items
      # from the abc grammar
      let(:items_from_grammar) { build_items_for_grammar(grm1) }
      let(:sample_gfg) { GFG::GrmFlowGraph.new(items_from_grammar) }

      let(:output) { StringIO.new('', 'w') }
      let(:sample_tracer) { ParseTracer.new(0, output, grm1_tokens) }

      # Default instantiation rule
      subject do
        GFGParsing.new(sample_gfg, grm1_tokens, sample_tracer)
      end

      context 'Initialization:' do
        it 'should be created with a GFG, tokens, trace' do
          expect { GFGParsing.new(sample_gfg, grm1_tokens, sample_tracer) }
            .not_to raise_error
        end

        it 'should know the input tokens' do
          expect(subject.tokens).to eq(grm1_tokens)
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
        def fill_first_set()
          subject.start_rule(subject.initial_entry, 0)
          subject.call_rule(subject.chart[0].last, 0)
          subject.start_rule(subject.chart[0].last, 0)
        end

        # Utility method to initialize the second entry set...
        def seed_second_set()
          # Cheating: we change surreptitiously the tokens to scan...
          subject.instance_variable_set(:@tokens, grm1_token_b)

          # Seeding second entry set...
          subject.scan_rule(0)
        end

        # Utility method used to invoke the private method 'push_entry'
        def push_entry(aParsing, *args)
          aParsing.send(:push_entry, *args)
        end

        it 'should push a parse entry to a given chart entry set' do
          expect(subject.chart[1]).to be_empty
          a_vertex = sample_gfg.find_vertex('A => a . A c')

          push_entry(subject, a_vertex, 1, 1, :scanning)
          expect(subject.chart[1].size).to eq(1)
          expect(subject.chart[1].first.vertex).to eq(a_vertex)

          # Pushing twice the same state must be no-op
          push_entry(subject, a_vertex, 1, 1, :scanning)
          expect(subject.chart[1].size).to eq(1)

          # Pushing to another entry set
          push_entry(subject, a_vertex, 1, 2, :scanning)
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

          expect(subject.chart[1]).to be_empty
          subject.scan_rule(0)
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

      context 'Parse forest building:' do
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
          parser = GFGEarleyParser.new(b_expr_grammar)
          tokens = expr_tokenizer('2 + 3 * 4', b_expr_grammar)
          parser.parse(tokens)
        end

        it 'should build a parse forest' do
          expect { subject.parse_forest }.not_to raise_error
          
        end
=begin
        it 'should create the root of a parse forest' do
          (entry_tracker, builder) = prepare_parse_forest(subject)
          # The root node should correspond to the start symbol and
          # its direct children should correspond to rhs of start production
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)

          expect(entry_tracker.entry_set_index).to eq(subject.tokens.size)
          expected_entry = 'P => S . | 0'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(builder.current_node.to_string(0)).to eq('S[0, 5]')
        end
=end
=begin
        it 'should use a reduce item for a matched non-terminal' do
          # Setup
          (entry_tracker, builder) = prepare_parse_tree(subject)
          # Same entry as in previous example

          # Given matched symbol is S[0, 5]
          # And its reduce item is S => S + M . | 0
          # Then add child nodes corresponding to the rhs symbols
          # And make M[?, 5] the current symbol
          subject.insert_matched_symbol(entry_tracker, builder)
          expected_text = <<-SNIPPET
P[0, 5]
+- S[0, 5]
   +- S[0, ?]
   +- +[?, ?]: '(nil)'
   +- M[?, 5]
SNIPPET
          root_text = builder.root.to_string(0)
          expect(root_text).to eq(expected_text.chomp)
          expected_entry = 'S => S + M . | 0'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(5)
          expect(builder.current_node.to_string(0)).to eq('M[?, 5]')

          # Second similar test

          # Given matched symbol is M[?, 5]
          # And its reduce item is M => M * T . | 2
          # Then add child nodes corresponding to the rhs symbols
          # And make T[?, 5] the current symbol
          subject.insert_matched_symbol(entry_tracker, builder)
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
          expected_entry = 'M => M * T . | 2'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(5)
          expect(builder.current_node.to_string(0)).to eq('T[?, 5]')
        end



        it 'should use a previous item for a terminal symbol' do
          # Setup
          (entry_tracker, builder) = prepare_parse_tree(subject)
          3.times do
            subject.insert_matched_symbol(entry_tracker, builder)
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
          expected_entry = 'T => integer . | 4'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(5)
          integer_repr = "integer[4, 5]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(integer_repr)

          # Given current tree symbol is integer[4, 5]: '(nil)'
          # And its previous item is T => . integer | 4
          # Then attach the token to the terminal node
          # And decrement the entry index by one
          # Make *[?, ?]: '(nil)' the current symbol
          subject.insert_matched_symbol(entry_tracker, builder)
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
          expected_entry = 'T => . integer | 4'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(4)
          next_symbol = "*[?, ?]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(next_symbol)
        end

        it 'should handle [no symbol before dot, terminal tree node] case' do
          # Setup
          (entry_tracker, builder) = prepare_parse_tree(subject)
          4.times do
            subject.insert_matched_symbol(entry_tracker, builder)
          end

          # Given current tree symbol is *[?, ?]: '(nil)'
          # And current dotted item is T => . integer | 4
          # When one retrieves the parse entry expecting the T
          # Then new parse entry is changed to: M => M * . T | 2
          subject.insert_matched_symbol(entry_tracker, builder)

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
          expected_entry = 'M => M * . T | 2'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(4)
          next_symbol = "*[?, ?]: '(nil)'"
          expect(builder.current_node.to_string(0)).to eq(next_symbol)

          subject.insert_matched_symbol(entry_tracker, builder)
          next_symbol = 'M[2, ?]'
          expect(builder.current_node.to_string(0)).to eq(next_symbol)
        end

        it 'should handle the end of parse tree generation' do
          # Begin setup
          is_done = false
          (entry_tracker, builder) = prepare_parse_tree(subject)
          16.times do
            is_done = subject.insert_matched_symbol(entry_tracker, builder)
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

          expected_entry = 'T => . integer | 0'
          expect(entry_tracker.parse_entry.to_s).to eq(expected_entry)
          expect(entry_tracker.entry_set_index).to eq(0)
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
=end
      end # context
    end # describe
  end # module
end # module

# End of file
