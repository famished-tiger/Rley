require_relative '../../spec_helper'
require_relative '../../../lib/rley/parser/token'
require_relative '../../../lib/rley/parser/earley_parser'
require_relative '../../../lib/rley/parser/parsing'
# Load the class under test
require_relative '../../../lib/rley/parser/parse_tree_builder'
require_relative '../support/grammar_abc_helper'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe ParseTreeBuilder do
      include GrammarABCHelper  # Mix-in module with builder for grammar abc

      let(:grammar_abc) do
        builder = grammar_abc_builder
        builder.grammar
      end

      let(:capital_a) { grammar_abc.name2symbol['A'] }
      let(:capital_s) { grammar_abc.name2symbol['S'] }
      let(:small_a) { grammar_abc.name2symbol['a'] }
      let(:small_b) { grammar_abc.name2symbol['b'] }
      let(:small_c) { grammar_abc.name2symbol['c'] }
      
      let(:start_prod) { grammar_abc.start_production } 

      let(:tokens_abc) do
        %w(a a b c c).map do |letter|
          Token.new(letter, grammar_abc.name2symbol[letter])
        end
      end

      let(:sample_parsing) do
        parser = EarleyParser.new(grammar_abc)
        result = parser.parse(tokens_abc)
      end
      
      subject { ParseTreeBuilder.new(start_prod, {low: 0, high: 5}) }

      context 'Initialization:' do
        it 'should be created with a proposition and a range' do
          expect { ParseTreeBuilder.new(start_prod, {}) }.not_to raise_error
        end

        it 'should have a root node at start' do
            expect(subject.root.symbol).to eq(capital_s)
        end

        it "should have current path at start" do
            expect(subject.current_path).not_to be_empty
        end

        it "should have current node at start" do
            expect(subject.current_node.symbol).to eq(capital_a)
        end
      end # context

      context 'Adding nodes to parse tree:' do
        it 'should process parse state for a non-terminal node' do
          # Expectation:
          # S[0, 5]
          # +- A[0,5]
          expect(subject.root.symbol).to eq(capital_s)
          expect(subject.root.children.size).to eq(1)
          child1 = subject.root.children[0]
          expect(child1.symbol).to eq(capital_a)
          expect(child1.range.low).to eq(0)
          expect(child1.range.high).to eq(5)
          expect(subject.current_node).to eq(child1)

          # Add children to A
          other_state = sample_parsing.chart.state_sets.last.states.first
          subject.use_complete_state(other_state)
          
          # Tree is:
          # S[0,5]
          # +- A[0,5]
          #    +- a[0, ?]
          #    +- A[?, ?]
          #    +- c[?, 5]
          expect(child1.children.size).to eq(3) # a A c
          %w(a A c).each_with_index do |letter, i|
            grm_symbol = grammar_abc.name2symbol[letter]
            expect(child1.children[i].symbol).to eq(grm_symbol)
          end
          expect(child1.children[0].range.low).to eq(0)
          expect(child1.children[-1].range.high).to eq(5)
          
          subject.move_down # ... to c
          subject.range = {low: 4}
          expect(child1.children[-1].range.low).to eq(4)
          expect(child1.children.last).to eq(subject.current_node)
          subject.move_back # ... to A
          expect(subject.current_node).to eq(child1.children[1])
          grand_child_A = subject.current_node

          other_state = sample_parsing.chart.state_sets[4].first
          subject.use_complete_state(other_state)
          expect(grand_child_A.children.size).to eq(3) # a A c
          %w(a A c).each_with_index do |letter, i|
            grm_symbol = grammar_abc.name2symbol[letter]
            expect(grand_child_A.children[i].symbol).to eq(grm_symbol)
          end
        end
      end # context

      context 'Moving the current node:' do
        it 'should move down to last child' do
          # Tree is:
          # S[0,?]
          # +- A[0,?]

          # Add children to A
          parse_state = sample_parsing.chart.state_sets.last.states.first
          subject.use_complete_state(parse_state)

          # Tree is:
          # S[0,?]
          # +- A[0,?]
          #    +- a[0, ?]
          #    +- A[?, ?]
          #    +- c[?, ?]
          subject.move_down # ...to grand-child c
          expect(subject.current_node.symbol).to eq(small_c)


          subject.move_back # ...to grand-child A
          expect(subject.current_node.symbol).to eq(capital_a)

          # Add more children
          other_state = sample_parsing.chart.state_sets[4].states.first
          subject.use_complete_state(other_state)

          # Tree is:
          # S[0,?]
          # +- A[0,?]
          #    +- a[0, ?]
          #    +- A[?, ?]
          #       +- a[?, ?]
          #       +- A[?, ?]
          #       +- c [?, ?]
          #    +- c[?, ?]

          subject.move_down # ...to grand-grand-child c
          expect(subject.current_node.symbol).to eq(small_c)

          subject.move_back # ...to grand-grand-child A
          expect(subject.current_node.symbol).to eq(capital_a)

          subject.move_back # ...to grand-grand-child a
          expect(subject.current_node.symbol).to eq(small_a)

          subject.move_back # ...to grand-child A
          expect(subject.current_node.symbol).to eq(capital_a)
          
          subject.move_back # ...to grand-child a
          expect(subject.current_node.symbol).to eq(small_a)

          subject.move_back # ...to child A
          expect(subject.current_node.symbol).to eq(capital_a)

          subject.move_back # ...to S
          expect(subject.current_node.symbol).to eq(capital_s)           
        end
      end # context
      
      context 'Parse tree building:' do       
        it 'should build a parse tree' do
          expect(subject.parse_tree).to be_kind_of(PTree::ParseTree)
          actual = subject.parse_tree
          expect(actual.root).to eq(subject.root)
        end
      end # context
      
    end # describe
  end # module
end # module

# End of file