require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/gfg/end_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe EndVertex do
      let(:sample_nt) { double('NT') }
      subject { EndVertex.new(sample_nt) }

      context 'Initialization:' do
        it 'should be created with a non-terminal symbol' do
          expect { EndVertex.new(sample_nt) }.not_to raise_error
        end

        it 'should know its label' do
          allow(sample_nt).to receive(:to_s).and_return('NT')
          expect(subject.label).to eq('NT.')
        end
      end # context
    end # describe
  end # module
end # module

# End of file