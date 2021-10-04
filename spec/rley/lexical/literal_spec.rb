# frozen_string_literal: true

require_relative '../../spec_helper'

require_relative '../../../lib/rley/syntax/terminal'

# Load the class under test
require_relative '../../../lib/rley/lexical/literal'

module Rley # Open this namespace to avoid module qualifier prefixes
  module Lexical # Open this namespace to avoid module qualifier prefixes
    describe Literal do
      let(:lexeme) { '12.34' }
      let(:a_terminal) { Syntax::Terminal.new('NUMBER') }
      let(:a_pos) { Position.new(3, 4) }

      context 'Initialization:' do
        # Default instantiation rule
        subject { Literal.new(lexeme.to_f, lexeme, a_terminal, a_pos) }

        it 'should be created with a value, lexeme, terminal and position' do
          expect { Literal.new(lexeme.to_f, lexeme, a_terminal, a_pos) }.not_to raise_error
        end

        it 'should know its value' do
          expect(subject.value).to eq(lexeme.to_f)
        end
      end # context
    end # describe
  end # module
end # module

# End of file
