# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/gfg/start_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe StartVertex do
      subject(:a_vertex) { described_class.new(sample_nt) }
      let(:sample_nt) { Syntax::NonTerminal.new('NT') }

      context 'Initialization:' do
        it 'is created with a non-terminal symbol' do
          expect { described_class.new(sample_nt) }.not_to raise_error
        end

        it 'knows its label' do
          allow(sample_nt).to receive(:to_s).and_return('NT')
          expect(a_vertex.label).to eq('.NT')
        end
      end # context

      context 'Provided services:' do
        it 'provides human-readable representation of itself' do
          pattern = /^#<Rley::GFG::StartVertex:\d+ label="\.NT"/
          expect(a_vertex.inspect).to match(pattern)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
