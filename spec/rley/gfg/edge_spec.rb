require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/gfg/end_vertex'

# Load the class under test
require_relative '../../../lib/rley/gfg/edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Edge do
      let(:vertex1) { StartVertex.new('from') }
      let(:vertex2) { StartVertex.new('to') }
      subject { Edge.new(vertex1, vertex2) }

      context 'Initialization:' do
        it 'should be created with two vertice arguments' do
          expect { Edge.new(vertex1, vertex2) }.not_to raise_error
        end

        it 'should be registered by the predecessor vertex' do
          expect(subject).to eq(vertex1.edges.last)
        end

        it 'should know the successor vertex' do
          expect(subject.successor).to eq(vertex2)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
