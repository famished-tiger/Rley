# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rley/syntax/non_terminal'

# Load the class under test
require_relative '../../../lib/rley/gfg/start_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe StartVertex do
      let(:sample_nt) { Syntax::NonTerminal.new('NT') }
      subject { StartVertex.new(sample_nt) }

      context 'Initialization:' do
        it 'should be created with a non-terminal symbol' do
          expect { StartVertex.new(sample_nt) }.not_to raise_error
        end

        it 'should know its label' do
          expect(sample_nt).to receive(:to_s).and_return('NT')
          expect(subject.label).to eq('.NT')
        end
      end # context

      context 'Provided services:' do
        it 'should provide human-readable representation of itself' do
          pattern = /^#<Rley::GFG::StartVertex:\d+ label="\.NT"/
          expect(subject.inspect).to match(pattern)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
