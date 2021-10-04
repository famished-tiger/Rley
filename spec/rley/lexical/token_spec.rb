# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'

# Load the class under test
require_relative '../../../lib/rley/lexical/token'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Lexical # Open this namespace to avoid module qualifier prefixes
    describe Token do
      let(:lexeme) { '"some text"' }
      let(:a_terminal) { Syntax::Terminal.new('if') }
      let(:a_pos) { Position.new(3, 4) }
      # Default instantiation rule
      subject { Token.new(lexeme, a_terminal, a_pos) }

      context 'Initialization:' do
        it 'could be created with a lexeme and a terminal ' do
          expect { Token.new(lexeme, a_terminal) }.not_to raise_error
        end

        it 'could be created with a lexeme, a terminal and position' do
          expect { Token.new(lexeme, a_terminal, a_pos) }.not_to raise_error
        end

        it 'should know its lexeme' do
          expect(subject.lexeme).to eq(lexeme)
        end

        it 'should know its terminal' do
          expect(subject.terminal).to eq(a_terminal)
        end

        it 'should know its position' do
          new_pos = Position.new(5, 7)
          subject.position = new_pos
          expect(subject.position).to eq(new_pos)
        end
      end # context

      context 'Initialization:' do
        it 'should accept a new position' do
          expect(subject.position).to eq(a_pos)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
