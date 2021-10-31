# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/lexical/token'
require_relative '../../../lib/rley/rgn/symbol_node'

# Load the class under test
require_relative '../../../lib/rley/rgn/sequence_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module RGN # Open this namespace to avoid module qualifier prefixes
    describe SequenceNode do
      let(:name1) { 'LPAR' }
      let(:name2) { 'arguments' }
      let(:name3) { 'RPAR' }
      let(:pos1) { Lexical::Position.new(3, 7) }
      let(:pos2) { Lexical::Position.new(3, 9) }
      let(:pos3) { Lexical::Position.new(3, 19) }
      let(:child1) { SymbolNode.new(pos1, name1) }
      let(:child2) { SymbolNode.new(pos2, name2) }
      let(:child3) { SymbolNode.new(pos3, name3) }

      # Default instantiation rule
      subject { SequenceNode.new([child1, child2, child3]) }

      context 'Initialization:' do
        it 'should be created with an array of child nodes' do
          children = [child1, child2, child3]
          expect { SequenceNode.new(children) }.not_to raise_error
        end

        it 'should know its subnodes' do
          expect(subject.subnodes.size).to eq(3)
          expect(subject.subnodes).to eq([child1, child2, child3])
        end
      end # context

      context 'Provided services:' do
        it 'should know its name' do
          expect(subject.name).to eq('seq_LPAR_arguments_RPAR')
        end
      end # context
    end # describe
  end # module
end # module

# End of file
