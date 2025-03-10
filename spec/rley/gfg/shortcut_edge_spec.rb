# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/gfg/shortcut_edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe ShortcutEdge do
      subject(:an_edge) { described_class.new(vertex1, vertex2) }

      let(:nt_b_sequence) { Rley::Syntax::NonTerminal.new('b_sequence') }
      let(:vertex1) { double('fake_vertex1') }
      let(:vertex2) { double('fake_vertex2') }

      context 'Initialization:' do
        it 'is created with two vertice arguments & a non-terminal' do
          allow(vertex1).to receive(:shortcut=)
          allow(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)

          expect { described_class.new(vertex1, vertex2) }
            .not_to raise_error
        end

        it 'knows the successor vertex' do
          allow(vertex1).to receive(:shortcut=)
          allow(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)

          expect(an_edge.successor).to eq(vertex2)
        end

        it 'knows the related terminal' do
          allow(vertex1).to receive(:shortcut=)
          allow(vertex1).to receive(:next_symbol).and_return(nt_b_sequence)

          expect(an_edge.nonterminal).to eq(nt_b_sequence)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
