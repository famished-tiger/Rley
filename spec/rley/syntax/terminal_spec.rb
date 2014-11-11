require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/terminal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes

  describe Terminal do
    let(:sample_name) { 'noun' }
    subject { Terminal.new(sample_name) }

    context 'Initialization:' do
      it 'should be created with a name' do
        expect { Terminal.new('noun') }.not_to raise_error
      end

      it 'should know its name' do
        expect(subject.name).to eq(sample_name)
      end
    end # context

  end # describe

  end # module
end # module

# End of file

