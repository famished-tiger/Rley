# frozen_string_literal: true

require_relative '../../spec_helper'

# Load the class under test
require_relative '../../../lib/rley/syntax/non_terminal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Syntax # Open this namespace to avoid module qualifier prefixes
    describe NonTerminal do
      subject(:a_nonterm) { described_class.new(sample_name) }
      let(:sample_name) { 'noun' }

      context 'Initialization:' do
        it 'is created with a name' do
          expect { described_class.new('noun') }.not_to raise_error
        end

        it 'knows its name' do
          expect(a_nonterm.name).to eq(sample_name)
        end

        it 'knows that is a not a terminal' do
          expect(a_nonterm).not_to be_terminal
        end
      end # context


      context 'Provided services:' do
        it 'knows whether it is nullable' do
          expect(a_nonterm.nullable?).to be_nil
          a_nonterm.nullable = true
          expect(a_nonterm).to be_nullable
          a_nonterm.nullable = false
          expect(a_nonterm).not_to be_nullable
        end

        it 'knows whether it is defined' do
          expect(a_nonterm.undefined?).to be_nil
          a_nonterm.undefined = true
          expect(a_nonterm).to be_undefined
          a_nonterm.undefined = false
          expect(a_nonterm).not_to be_undefined
        end

        it 'knows whether it is generative' do
          expect(a_nonterm.generative?).to be_nil
          a_nonterm.generative = true
          expect(a_nonterm).to be_generative
          a_nonterm.generative = false
          expect(a_nonterm).not_to be_generative
        end
      end # context
    end # describe
  end # module
end # module

# End of file
