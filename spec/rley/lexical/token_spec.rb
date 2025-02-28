# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'

# Load the class under test
require_relative '../../../lib/rley/lexical/token'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Lexical # Open this namespace to avoid module qualifier prefixes
    describe Token do
      # Default instantiation rule
      subject(:a_token) { described_class.new(lexeme, a_terminal, a_pos) }

      let(:lexeme) { '"some text"' }
      let(:a_terminal) { Syntax::Terminal.new('if') }
      let(:a_pos) { Position.new(3, 4) }

      context 'Initialization:' do
        it 'is created with a lexeme and a terminal' do
          expect { described_class.new(lexeme, a_terminal) }.not_to raise_error
        end

        it 'is created with a lexeme, a terminal and position' do
          expect { described_class.new(lexeme, a_terminal, a_pos) }.not_to raise_error
        end

        it 'knows its lexeme' do
          expect(a_token.lexeme).to eq(lexeme)
        end

        it 'knows its terminal' do
          expect(a_token.terminal).to eq(a_terminal)
        end

        it 'knows its position' do
          new_pos = Position.new(5, 7)
          a_token.position = new_pos
          expect(a_token.position).to eq(new_pos)
        end
      end # context

      context 'Provided services:' do
        it 'accepts a new position' do
          expect(a_token.position).to eq(a_pos)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
