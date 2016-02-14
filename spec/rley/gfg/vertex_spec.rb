require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/gfg/vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe Vertex do
      subject { Vertex.new() }

      context 'Initialization:' do
        it 'should be created without argument' do
          expect { Vertex.new() }.not_to raise_error
        end
        
        it "shouldn't have edges at start" do
          expect(subject.edges.empty?).to eq(true)
        end
      end # context
      
      context 'Provided services:' do
        it 'should accept new edges' do
          edge1 = double('fake-edge1')
          edge2 = double('fake-edge2')
          
          expect { subject.add_edge(edge1) }.not_to raise_error
          expect(subject.edges.size).to eq(1)
          expect(subject.edges.last).to eq(edge1)
          expect { subject.add_edge(edge2) }.not_to raise_error          
          expect(subject.edges.size).to eq(2)
          expect(subject.edges.last).to eq(edge2)
        end
      end # context
    end # describe
  end # module
end # module

# End of file