# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/grm_symbol'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe GrmSymbol do
      subject(:grammar_symb) { described_class.new(sample_name) }
      let(:sample_name) { 'NP' }

      context 'Initialization:' do
        it 'is created with a name' do
          expect { described_class.new('NP') }.not_to raise_error
        end

        it 'knows its name' do
          expect(grammar_symb.name).to eq(sample_name)
        end
      end # context

      context 'Provided services:' do
        it 'gives its text representation' do
          expect(grammar_symb.to_s).to eq(sample_name)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
