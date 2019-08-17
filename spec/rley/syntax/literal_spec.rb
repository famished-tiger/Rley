# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/literal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe Literal do
      let(:sample_name) { 'ordinal' }
      subject { Literal.new(sample_name, /\d+/) }

      context 'Initialization:' do
        it 'should be created with a name and regexp' do
          expect { Literal.new(sample_name, /\d+/) }.not_to raise_error
        end

        it 'should know its name' do
          expect(subject.name).to eq(sample_name)
        end

        it 'should know its pattern' do
          expect(subject.pattern).to eq(/\d+/)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
