require_relative '../../spec_helper'
require_relative '../../../lib/rley/tokens/token'

# Load the class under test
require_relative '../../../lib/rley/parser/error_reason'
module Rley # Open this namespace to avoid module qualifier prefixes
  module Parser # Open this namespace to avoid module qualifier prefixes
    describe NoInput do
      context 'Initialization:' do
        # Default instantiation rule
        subject { NoInput.new }

        it 'should be created without argument' do
          expect { NoInput.new }.not_to raise_error
        end

        it 'should know the error position' do
          expect(subject.position).to eq(0)
        end
      end # context

      context 'Provided services:' do
        it 'should emit a standard message' do
          text = 'Input cannot be empty.'
          expect(subject.to_s).to eq(text)
          expect(subject.message).to eq(text)
        end

        it 'should give a clear inspection text' do
          text = 'Rley::Parser::NoInput: Input cannot be empty.'
          expect(subject.inspect).to eq(text)
        end
      end # context
    end # describe

    describe ExpectationNotMet do
      let(:err_token) { double('fake-token') }
      let(:terminals) do
        %w[PLUS LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      # Default instantiation rule
      subject { ExpectationNotMet.new(3, err_token, terminals) }

      context 'Initialization:' do
        it 'should be created with arguments' do
          expect do 
            ExpectationNotMet.new(3, err_token, terminals) 
          end.not_to raise_error
        end

        it 'should know the error position' do
          expect(subject.position).to eq(3)
        end

        it 'should know the expected terminals' do
          expect(subject.expected_terminals).to eq(terminals)
        end
      end # context
    end # describe

    describe UnexpectedToken do
      let(:err_lexeme) { '-' }
      let(:err_terminal) { Syntax::Terminal.new('MINUS') }
      let(:err_token) { Tokens::Token.new(err_lexeme, err_terminal) }
      let(:terminals) do
        %w[PLUS LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      # Default instantiation rule
      subject { UnexpectedToken.new(3, err_token, terminals) }

      context 'Initialization:' do
        it 'should be created with arguments' do
          expect do 
            UnexpectedToken.new(3, err_token, terminals) 
          end.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'should emit a message' do
          text = <<MSG_END
Syntax error at or near token 4 >>>-<<<
Expected one of: ['PLUS', 'LPAREN'], found a 'MINUS' instead.
MSG_END
          expect(subject.to_s).to eq(text.chomp)
          expect(subject.message).to eq(text.chomp)
        end
      end # context
    end # describe

    describe PrematureInputEnd do
      let(:err_lexeme) { '+' }
      let(:err_terminal) { Syntax::Terminal.new('PLUS') }
      let(:err_token) { Tokens::Token.new(err_lexeme, err_terminal) }
      let(:terminals) do
        %w[INT LPAREN].map { |name| Syntax::Terminal.new(name) }
      end

      # Default instantiation rule
      subject { PrematureInputEnd.new(3, err_token, terminals) }

      context 'Initialization:' do
        it 'should be created with arguments' do
          expect do 
            PrematureInputEnd.new(3, err_token, terminals) 
          end.not_to raise_error
        end
      end # context

      context 'Provided services:' do
        it 'should emit a message' do
          text = <<MSG_END
Premature end of input after '+' at position 4
Expected one of: ['INT', 'LPAREN'].
MSG_END
          expect(subject.to_s).to eq(text.chomp)
          expect(subject.message).to eq(text.chomp)
        end
      end # context
    end # describe
  end # module
end # module
# End of file
