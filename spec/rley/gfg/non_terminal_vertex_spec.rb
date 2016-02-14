require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/gfg/non_terminal_vertex'

module Rley # Open this namespace to avoid module qualifier prefixes
  module GFG # Open this namespace to avoid module qualifier prefixes
    describe NonTerminalVertex do
      let(:sample_nt) { double('fake-non-terminal') }
      subject { NonTerminalVertex.new(sample_nt) }

      context 'Initialization:' do
        it 'should be created with a non-terminal symbol' do
          expect { NonTerminalVertex.new(sample_nt) }.not_to raise_error
        end

        it 'should know its non-terminal' do
          expect(subject.non_terminal).to eq(sample_nt)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
