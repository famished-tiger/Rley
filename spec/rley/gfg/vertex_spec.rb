# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/gfg/vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Vertex do
      subject(:a_vertex) { described_class.new }

      context 'Initialization:' do
        it 'is created without argument' do
          expect { described_class.new }.not_to raise_error
        end

        it "doesn't have edges at start" do
          expect(a_vertex.edges.empty?).to be(true)
        end
      end # context

      context 'Provided services:' do
        it 'knows whether it has a dot at the end of the rhs' do
          expect(a_vertex).not_to be_complete
        end

        it 'knows the previous symbol (if any) in the rhs' do
          expect(a_vertex.prev_symbol).to be_nil
        end

        it 'knows the next symbol (if any) in the rhs' do
          expect(a_vertex.next_symbol).to be_nil
        end

        it 'accepts at most one new edge' do
          edge1 = double('fake-edge1')
          edge2 = double('fake-edge2')

          expect { a_vertex.add_edge(edge1) }.not_to raise_error
          expect(a_vertex.edges.size).to eq(1)
          expect(a_vertex.edges.last).to eq(edge1)

          err = StandardError
          msg = 'At most one edge accepted'
          expect { a_vertex.add_edge(edge2) }.to raise_error err, msg
          expect(a_vertex.edges.size).to eq(1)
          expect(a_vertex.edges.last).to eq(edge1)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
