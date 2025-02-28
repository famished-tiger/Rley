# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/gfg/end_vertex'

# Load the class under test
require_relative '../../../lib/rley/gfg/edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Edge do
      subject(:an_edge) { described_class.new(vertex1, vertex2) }

      let(:vertex1) { StartVertex.new('from') }
      let(:vertex2) { StartVertex.new('to') }

      context 'Initialization:' do
        it 'is created with two vertice arguments' do
          expect { described_class.new(vertex1, vertex2) }.not_to raise_error
        end

        it 'is registered by the predecessor vertex' do
          expect(an_edge).to eq(vertex1.edges.last)
        end

        it 'knows the successor vertex' do
          expect(an_edge.successor).to eq(vertex2)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
