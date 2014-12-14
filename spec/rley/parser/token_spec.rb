require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'

# Load the class under test
require_relative '../../../lib/rley/parser/token'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe Token do
      let(:lexeme) { '"some text"' }
      let(:sample_terminal) { Syntax::Terminal.new('if') }

      context 'Initialization:' do
        # Default instantiation rule
        subject { Token.new(lexeme, sample_terminal) }

        it 'should be created with a lexeme and a terminal argument' do
          expect { Token.new(lexeme, sample_terminal) }.not_to raise_error
        end

        it 'should know its lexeme' do
          expect(subject.lexeme).to eq(lexeme)
        end

        it 'should know its terminal' do
          expect(subject.terminal).to eq(sample_terminal)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
