require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/non_terminal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes

  describe NonTerminal do
    let(:sample_name) { 'noun' }
    subject { NonTerminal.new(sample_name) }

    context 'Initialization:' do
      it 'should be created with a name' do
        expect { NonTerminal.new('noun') }.not_to raise_error
      end

      it 'should know its name' do
        expect(subject.name).to eq(sample_name)
      end
    end # context

  end # describe

  end # module
end # module

# End of file

