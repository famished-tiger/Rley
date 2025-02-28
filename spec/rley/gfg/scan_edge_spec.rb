# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/gfg/end_vertex'

# Load the class under test
require_relative '../../../lib/rley/gfg/scan_edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe ScanEdge do
      subject(:an_edge) { described_class.new(vertex1, vertex2, sample_terminal) }

      let(:vertex1) { StartVertex.new('from') }
      let(:vertex2) { StartVertex.new('to') }
      let(:sample_terminal) { double('fake-terminal') }

      context 'Initialization:' do
        it 'is created with two vertice arguments & a terminal' do
          v1 = vertex1
          v2 = vertex2
          expect { described_class.new(v1, v2, sample_terminal) }.not_to raise_error
        end

        it 'knows the related terminal' do
          expect(an_edge.terminal).to eq(sample_terminal)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
