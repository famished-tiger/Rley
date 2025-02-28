# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../lib/rley/lexical/token'

# Load the class under test
require_relative '../../../lib/rley/parser/error_reason'
module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe NoInput do
      # Default instantiation rule
      subject(:an_exception) { described_class.new }

      context 'Initialization:' do
        it 'is created without argument' do
          expect { described_class.new }.not_to raise_error
        end

        it 'knows the error token rank' do
          expect(an_exception.rank).to eq(0)
        end
      end # context

      context 'Provided services:' do
        it 'emits a standard message' do
          text = 'Input cannot be empty.'
          expect(an_exception.to_s).to eq(text)
          expect(an_exception.message).to eq(text)
        end

        it 'gives a clear inspection text' do
          text = 'Rley::Parser::NoInput: Input cannot be empty.'
          expect(an_exception.inspect).to eq(text)
        end
      end # context
    end # describe

    describe ExpectationNotMet do
      # Default instantiation rule
      subject(:an_exception) { described_class.new(3, err_token, terminals) }

      let(:err_token) { double('fake-token') }
      let(:terminals) do
        %w[PLUS LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      context 'Initialization:' do
        it 'is created with arguments' do
          expect do
            described_class.new(3, err_token, terminals)
          end.not_to raise_error
        end

        it 'knows the error position' do
          expect(an_exception.rank).to eq(3)
        end

        it 'knows the expected terminals' do
          expect(an_exception.expected_terminals).to eq(terminals)
        end
      end # context
    end # describe

    describe UnexpectedToken do
      # Default instantiation rule
      subject(:an_exception) { described_class.new(3, err_token, terminals) }

      let(:err_lexeme) { '-' }
      let(:err_terminal) { Syntax::Terminal.new('MINUS') }
      let(:pos) { Lexical::Position.new(3, 4) }
      let(:err_token) { Lexical::Token.new(err_lexeme, err_terminal, pos) }
      let(:terminals) do
        %w[PLUS LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      context 'Initialization:' do
        it 'is created with arguments' do
          expect do
            described_class.new(3, err_token, terminals)
          end.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'emits a message' do
          text = <<MESSAGE_END
Syntax error at or near token line 3, column 4 >>>-<<<
Expected one of: ['PLUS', 'LPAREN'], found a 'MINUS' instead.
MESSAGE_END
          expect(an_exception.to_s).to eq(text.chomp)
          expect(an_exception.message).to eq(text.chomp)
        end
      end # context
    end # describe

    describe PrematureInputEnd do
      # Default instantiation rule
      subject(:an_exception) { described_class.new(3, err_token, terminals) }

      let(:err_lexeme) { '+' }
      let(:err_terminal) { Syntax::Terminal.new('PLUS') }
      let(:pos) { Lexical::Position.new(3, 4) }
      let(:err_token) { Lexical::Token.new(err_lexeme, err_terminal, pos) }
      let(:terminals) do
        %w[INT LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      context 'Initialization:' do
        it 'is created with arguments' do
          expect do
            described_class.new(3, err_token, terminals)
          end.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'emits a message' do
          text = <<MESSAGE_END
Premature end of input after '+' at position line 3, column 4
Expected one of: ['INT', 'LPAREN'].
MESSAGE_END
          expect(an_exception.to_s).to eq(text.chomp)
          expect(an_exception.message).to eq(text.chomp)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
