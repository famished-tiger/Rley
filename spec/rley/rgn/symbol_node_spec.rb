# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/lexical/token'

# Load the class under test
require_relative '../../../lib/rley/rgn/symbol_node'

module Rley # Open this namespace to avoid module qualifier prefixes
  module RGN # Open this namespace to avoid module qualifier prefixes
    describe SymbolNode do
      let(:a_name) { 'arguments' }
      let(:a_pos) { Lexical::Position.new(3, 4) }

      context 'Initialization:' do
        # Default instantiation rule
        subject(:a_node) { described_class.new(a_pos, a_name) }

        it 'is created with a name and position' do
          expect { described_class.new(a_pos, a_name) }.not_to raise_error
        end

        it 'knows its name' do
          expect(a_node.name).to eq(a_name)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
