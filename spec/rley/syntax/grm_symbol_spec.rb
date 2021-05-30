# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/grm_symbol'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe GrmSymbol do
      let(:sample_name) { 'NP' }
      subject { GrmSymbol.new(sample_name) }

      context 'Initialization:' do
        it 'should be created with a name' do
          expect { GrmSymbol.new('NP') }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq(sample_name)
        end
      end # context

      context 'Provided services:' do
        it 'should give its text representation' do
          expect(subject.to_s).to eq(sample_name)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
