require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/verbatim_symbol'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe VerbatimSymbol do
      let(:sample_name) { 'cheapest' }
      subject { VerbatimSymbol.new(sample_name) }

      context 'Initialization:' do
        it 'should be created with a word' do
          expect { VerbatimSymbol.new('cheapest') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq(sample_name)
        end

        it 'should know its text representation' do
          expect(subject.text).to eq(sample_name)
        end
      end # context

    end # describe
  end # module
end # module

# End of file
