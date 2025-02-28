# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/terminal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe Terminal do
      subject(:the_terminal) { described_class.new(sample_name) }

      let(:sample_name) { 'noun' }

      context 'Initialization:' do
        it 'is created with a name' do
          expect { described_class.new('noun') }.not_to raise_error
        end

        it 'knows its name' do
          expect(the_terminal.name).to eq(sample_name)
        end

        it 'knows that is a terminal symbol' do
          expect(the_terminal).to be_terminal
        end

        it "knows that isn't nullable" do
          expect(the_terminal).not_to be_nullable
        end

        it 'knows that it is generative' do
          expect(the_terminal).to be_generative
        end
      end # context
    end # describe
  end # module
end # module

# End of file
