require_relative '../../spec_helper'
require 'pp'

require_relative '../support/grammar_abc_helper'
require_relative '../../../lib/rley/parser/grm_items_builder'

# Load the module under test
require_relative '../../../lib/rley/gfg/grm_flow_graph'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe GrmFlowGraph do
      include GrammarABCHelper # Mix-in module with builder for grammar abc

      # Helper method. Create an array of dotted items
      # from the given grammar
      def build_items_for_grammar(aGrammar)
        helper = Object.new
        helper.extend(Parser::GrmItemsBuilder)
        return helper.build_dotted_items(aGrammar)
      end

      # Check that the passed graph has exactly the same
      # vertices and edges as expected
      def compare_graph_expectations(aGraph, expectations)
        i = 0
        aGraph.vertices.each do |vertex|
          vertex.edges.each do |edge|
            representation = vertex.label + edge.to_s
            expect(representation).to eq(expectations[i])
            i += 1
          end
        end
      end

      # Factory method. Build a production with the given sequence
      # of symbols as its rhs.
      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      # Helper method. Create an array of dotted items
      # from the abc grammar
      let(:items_from_grammar) { build_items_for_grammar(grammar_abc) }

      # Default instantiation rule
      subject { GrmFlowGraph.new(items_from_grammar) }


      context 'Initialization:' do
        it 'should be created with an array of dotted items' do
          expect { GrmFlowGraph.new(items_from_grammar) }.not_to raise_error
        end

        it 'should have the correct number of vertices' do
          # Number of vertices = count of dotted items +...
          #   ... 2 * count of non-terminals
          count_vertices = 2 * grammar_abc.non_terminals.size
          count_vertices += items_from_grammar.size
          expect(subject.vertices.size).to eq(count_vertices)
        end

        it 'should have for each non-terminal one start and end vertex' do
          # Iterate over all non-terminals of grammar...
          grammar_abc.non_terminals.each do |nterm|
            # ...to each non-terminal there should be a start vertex
            start_vertex = subject.start_vertex_for[nterm]
            expect(start_vertex).to be_kind_of(StartVertex)
            expect(start_vertex.label).to eq(".#{nterm}")

            # ...to each non-terminal there should be an end vertex
            end_vertex = subject.end_vertex_for[nterm]
            expect(end_vertex).to be_kind_of(EndVertex)
            expect(end_vertex.label).to eq("#{nterm}.")
          end
        end

        it 'should have one or more entry edges per start vertex' do
          subject.start_vertex_for.values.each do |a_start|
            expect(a_start.edges.size >= 1).to be_truthy
            a_start.edges.each do |edge|
              expect(edge.successor.dotted_item.at_start?).to be_truthy
            end
          end
        end

        it 'should have the correct graph structure' do
          # We use the abc grammar
          expected = [
            '.S --> S => . A',
            '.A --> A => . a A c',
            '.A --> A => . b',
            'A. --> S => A .',
            'A. --> A => a A . c',
            'S => . A --> .A',
            'S => A . --> S.',
            'A => . a A c -a-> A => a . A c',
            'A => a . A c --> .A',
            'A => a A . c -c-> A => a A c .',
            'A => a A c . --> A.',
            'A => . b -b-> A => b .',
            'A => b . --> A.'
          ]

          compare_graph_expectations(subject, expected)
        end

        it 'should handle empty productions' do
            builder = Rley::Syntax::GrammarBuilder.new
            builder.add_terminals('a')
            builder.add_production('S' => 'A')
            builder.add_production('A' => 'a')
            builder.add_production('A' => []) # empty rhs

            grammar = builder.grammar
            items = build_items_for_grammar(grammar)

            graph = GrmFlowGraph.new(items)
            expected = [
              '.S --> S => . A',
              '.A --> A => . a',
              '.A --> A => .',
              'A. --> S => A .',
              'S => . A --> .A',
              'S => A . --> S.',
              'A => . a -a-> A => a .',
              'A => a . --> A.',
              'A => . --> A.'
            ]
            
            compare_graph_expectations(graph, expected)
        end
      end # context
    end # describe
  end # module
end # module

# End of file