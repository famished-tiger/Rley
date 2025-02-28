# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/gfg/non_terminal_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalVertex do
      subject(:a_vertex) { described_class.new(sample_nt) }
      let(:sample_nt) { double('fake-non-terminal') }

      context 'Initialization:' do
        it 'is created with a non-terminal symbol' do
          expect { described_class.new(sample_nt) }.not_to raise_error
        end

        it 'knows its non-terminal' do
          expect(a_vertex.non_terminal).to eq(sample_nt)
        end


        it 'accepts at more than one outgoing edge' do
          edge1 = double('fake-edge1')
          edge2 = double('fake-edge2')

          expect { a_vertex.add_edge(edge1) }.not_to raise_error
          expect(a_vertex.edges.size).to eq(1)
          expect(a_vertex.edges.last).to eq(edge1)

          expect { a_vertex.add_edge(edge2) }.not_to raise_error
          expect(a_vertex.edges.size).to eq(2)
          expect(a_vertex.edges.last).to eq(edge2)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
