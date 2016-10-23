require_relative '../../spec_helper'
require 'stringio'

require_relative '../../../lib/rley/syntax/terminal'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/parser/parse_entry'
require_relative '../../../lib/rley/parser/parse_tracer'
require_relative '../../../lib/rley/parser/grm_items_builder'
require_relative '../../../lib/rley/gfg/grm_flow_graph'
require_relative '../support/grammar_abc_helper'


# Load the class under test
require_relative '../../../lib/rley/parser/gfg_chart'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe GFGChart do
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      # Helper method. Create an array of dotted items
      # from the given grammar
      def build_items_for_grammar(aGrammar)
        helper = Object.new
        helper.extend(Parser::GrmItemsBuilder)
        return helper.build_dotted_items(aGrammar)
      end

      let(:count_token) { 20 }
      let(:output) { StringIO.new('', 'w') }

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:token_seq) do
        literals = %w(a a b c c)
        literals.map { |lexeme| Token.new(lexeme, nil) }
      end

      # Helper method. Create an array of dotted items
      # from the abc grammar
      let(:items_from_grammar) { build_items_for_grammar(grammar_abc) }
      let(:sample_gfg) { GFG::GrmFlowGraph.new(items_from_grammar) }
      let(:sample_tracer) { ParseTracer.new(0, output, token_seq) }
      let(:sample_start_symbol) { sample_gfg.start_vertex.non_terminal }


      # Default instantiation rule
      subject { GFGChart.new(count_token, sample_gfg, sample_tracer) }


      context 'Initialization:' do
        it 'should be created with start vertex, token count, tracer' do
          expect { GFGChart.new(count_token, sample_gfg, sample_tracer) }
            .not_to raise_error
        end

        it 'should have correct entry set count' do
          expect(subject.sets.size).to eq(count_token + 1)
        end

        it 'should reference a tracer' do
          expect(subject.tracer).to eq(sample_tracer)
        end

        it 'should know the start symbol' do
          expect(subject.start_symbol).to eq(sample_start_symbol)
        end
        
        it 'should know the initial parse entry' do
          expect(subject.initial_entry.vertex).to eq(sample_gfg.start_vertex)
          expect(subject.initial_entry.origin).to eq(0)
        end
=begin

        it 'should know the start dotted rule' do
          expect(subject.start_dotted_rule).to eq(dotted_rule)
        end


=end
      end # context

      context 'Provided services:' do
=begin
        let(:t_a) { Syntax::Terminal.new('a') }
        let(:t_b) { Syntax::Terminal.new('b') }
        let(:t_c) { Syntax::Terminal.new('c') }
        let(:nt_sentence) { Syntax::NonTerminal.new('sentence') }

        let(:sample_prod) do
          Syntax::Production.new(nt_sentence, [t_a, t_b, t_c])
        end

        let(:origin_val) { 3 }
        let(:dotted_rule) { DottedItem.new(sample_prod, 2) }
        let(:complete_rule) { DottedItem.new(sample_prod, 3) }
        let(:sample_parse_state) { ParseState.new(dotted_rule, origin_val) }
        let(:sample_tracer) { ParseTracer.new(1, output, token_seq) }

        # Factory method.
        def parse_state(origin, aDottedRule)
          ParseState.new(aDottedRule, origin)
        end


        it 'should trace its initialization' do
          subject[0]  # Force constructor call here
          expectation = <<-SNIPPET
['I', 'saw', 'John', 'with', 'a', 'dog']
|.  I   . saw  . John . with .  a   . dog  .|
|>      .      .      .      .      .      .| [0:0] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectation)
        end

        it 'should trace parse state pushing' do
          subject[0]  # Force constructor call here
          output.string = ''

          subject.push_state(dotted_rule, 3, 5, :prediction)
          expectation = <<-SNIPPET
|.      .      .      >      .| [3:5] sentence => A B . C
SNIPPET
          expect(output.string).to eq(expectation)
        end
=end
      end # context
    end # describe
  end # module
end # module

# End of file
