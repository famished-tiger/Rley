require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/gfg/shortcut_edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Edge do
      let(:nt_b_sequence) { Rley::Syntax::NonTerminal.new('b_sequence') }

      let(:vertex1) { double('fake_vertex1') }
      let(:vertex2) { double('fake_vertex2') }
      subject { ShortcutEdge.new(vertex1, vertex2) }

      context 'Initialization:' do
        it 'should be created with two vertice arguments & a non-terminal' do
          expect(vertex1).to receive(:shortcut=)
          expect(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)

          expect { ShortcutEdge.new(vertex1, vertex2) }
            .not_to raise_error
        end

        it 'should know the successor vertex' do
          expect(vertex1).to receive(:shortcut=)
          expect(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)
          
          expect(subject.successor).to eq(vertex2)
        end

        it 'should know the related terminal' do
          expect(vertex1).to receive(:shortcut=)
          expect(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)

          expect(subject.nonterminal).to eq(nt_b_sequence)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
