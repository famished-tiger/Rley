require_relative '../../spec_helper'

require_relative '../support/grammar_abc_helper'
require_relative '../../../lib/rley/base/grm_items_builder'

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
        helper.extend(Base::GrmItemsBuilder)
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

        it 'should know its main start vertex' do
          expect(subject.start_vertex).to eq(subject.vertices.first)
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
          subject.start_vertex_for.each_value do |a_start|
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

        it 'should have shortcut edges' do
          subject.vertices.each do |a_vertex|
            next unless a_vertex.kind_of?(ItemVertex)
            if a_vertex.next_symbol.kind_of?(Syntax::NonTerminal)
              expect(a_vertex.shortcut).not_to be_nil            
              my_d_item = a_vertex.dotted_item
              
              # Retrieve dotted item of shortcut successor
              other_d_item = a_vertex.shortcut.successor.dotted_item
              
              # Now the checks...
              expect(my_d_item.production).to eq(other_d_item.production)
              expect(my_d_item.position).to eq(other_d_item.prev_position)
            else
              expect(a_vertex.shortcut).to be_nil
            end
          end
        end
      end # context
      
      context 'Provided services:' do
        let(:problematic_grammar) do
          # Based on grammar example in book
          # C. Fisher, R. LeBlanc, "Crafting a Compiler"; page 98
          builder = Rley::Syntax::GrammarBuilder.new
          builder.add_terminals('a', 'b', 'c')
          builder.add_production('S' => 'A')
          builder.add_production('S' => 'B')
          builder.add_production('A' => 'a')
          # There is no edge between .B and B => B . b => non-generative
          builder.add_production('B' => %w[B b])
          
          # Non-terminal symbol C is unreachable
          builder.add_production('C' => 'c')  

          # And now build the grammar...
          builder.grammar       
        end
      
        it 'should provide depth-first traversal' do
          result = []
          subject.traverse_df(subject.start_vertex) do |vertex|
            result << vertex.label
          end

          expected = [
            '.S',
            'S => . A',
            '.A',
            'A => . a A c',
            'A => a . A c',
            'A => a A . c',
            'A => a A c .',
            'A.',
            'A => . b',
            'A => b .',
            'S => A .',
            'S.'
          ]
          expect(result).to eq(expected)
        end
        
        it 'should perform a diagnosis of a correct grammar' do
          expect { subject.diagnose }.not_to raise_error
          grammar_abc.non_terminals.each do |nterm|
            expect(nterm).not_to be_undefined
            expect(nterm).not_to be_unreachable
          end
        end
        
        it 'should detect when a non-terminal is unreachable' do
          grammar = problematic_grammar
          items = build_items_for_grammar(grammar)

          graph = GrmFlowGraph.new(items)       
          expect { graph.diagnose }.not_to raise_error
          grammar.non_terminals.each do |nterm|
            expect(nterm).not_to be_undefined
          end
          
          unreachable = grammar.non_terminals.select(&:unreachable?)
          expect(unreachable.size).to eq(1)
          expect(unreachable[0].name).to eq('C')
        end        
      end # context      
    end # describe
  end # module
end # module

# End of file
