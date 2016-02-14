require_relative '../../spec_helper'

require_relative '../../../lib/rley/gfg/start_vertex'
require_relative '../../../lib/rley/gfg/end_vertex'

# Load the class under test
require_relative '../../../lib/rley/gfg/epsilon_edge'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Edge do
      let(:vertex1) { StartVertex.new('from') }
      let(:vertex2) { StartVertex.new('to') }
      subject { EpsilonEdge.new(vertex1, vertex2) }

      context 'Initialization:' do
        it 'should be created with two vertice arguments' do
          expect { EpsilonEdge.new(vertex1, vertex2) }.not_to raise_error
        end
      end # context
    end # describe
  end # module
end # module

# End of file