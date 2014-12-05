require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/grammar_builder'
# Load the class under test
require_relative '../../../lib/rley/ptree/parse_tree'

module Rley # Open this namespace to avoid module qualifier prefixes
  module PTree # Open this namespace to avoid module qualifier prefixes
    describe ParseTree do
      let(:sample_grammar) do
        builder = Syntax::GrammarBuilder.new
        builder.add_terminals('a', 'b', 'c')
        builder.add_production('S' => ['A'])
        builder.add_production('A' => %w(a A c))
        builder.add_production('A' => ['b'])
        builder.grammar
      end

      let(:sample_prod) { sample_grammar.rules[0] }
      let(:sample_range) { {low:0, high:5} }
      subject { ParseTree.new(sample_prod, sample_range) }

      context 'Initialization:' do
        it 'should be created with a production and a range' do
          construction = -> { ParseTreeNode.new(sample_prod, sample_range) }
          expect(construction).not_to raise_error
        end

        it 'should know its root node' do
          its_root = subject.root
          expect(its_root.symbol.name).to eq('S')
          expect(its_root.range).to eq(sample_range)
          expect(its_root.children.size).to eq(1)
          expect(its_root.children[0].symbol.name).to eq('A')
          expect(its_root.children[0].range).to eq(sample_range)
        end

        it 'should know its current path' do
          path = subject.current_path

          # Given the tree:
          # S[0,5]
          # +- A[0,5] <- current node
          # Expected path: [S[0,5], 0, A[0,5]]
          expect(path.size).to eq(3)
          expect(path[0]).to eq(subject.root)
          expect(path[1]).to eq(0)
          expect(path[2]).to eq(subject.root.children[0])
          expect(path[2].range).to eq(sample_range)
        end
      end # context

      context 'Provided service:' do
        it 'should add children to current node' do
          subject.add_children(sample_grammar.rules[1], sample_range)

          # Given the tree:
          # S[0,5]
          # +- A[0,5]
          #    +-a[0,nil]
          #    +-A[nil, nil]
          #    +-c[nil, 5] <- current node
          # Expected path: [S[0,5], 0, A[0,5], 2, c[nil, 5]]
          path = subject.current_path
          expect(path.size).to eq(5)
          expect(path[3]).to eq(2)
          expect(path[4].symbol.name).to eq('c')
          expect(path[4].range.low).to be_nil
          expect(path[4].range.high).to eq(5)
        end

        it 'should step back to a previous sibling node' do
          subject.add_children(sample_grammar.rules[1], sample_range)
          subject.step_back(4)
          # Expected tree:
          # S[0,5]
          # +- A[0,5]
          #    +-a[0,nil]
          #    +-A[nil, 4] <- current node
          #    +-c[4, 5]
          # Expected path: [S[0,5], 0, A[0,5], 1, A[nil, 4]]
          path = subject.current_path
          expect(path.size).to eq(5)
          expect(path[3]).to eq(1)
          expect(path[4].symbol.name).to eq('A')
          expect(path[4].range.low).to be_nil
          expect(path[4].range.high).to eq(4)
        end
      end

    end # describe
  end # module
end # module

# End of file