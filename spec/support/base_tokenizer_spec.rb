# frozen_string_literal: true

require_relative '../spec_helper'

# Load the class under test
require_relative '../../lib/support/base_tokenizer'

describe BaseTokenizer do
  let(:sample_input) { '7 + (8 + 9)' }

  context 'Standard creation & initialization:' do
    subject(:tokenizer) { described_class.new(sample_input) }

    it 'is initialized with a text argument' do
      expect { described_class.new(sample_input) }.not_to raise_error
    end

    it 'has a scanner initialized' do
      expect(tokenizer.scanner).to be_a(StringScanner)
    end

    it 'has line number initialized' do
      expect(tokenizer.lineno).to eq(1)
    end
  end # context


  context 'Provided services:' do
    # Simplistic tokenizer.
    # rubocop: disable Lint/ConstantDefinitionInBlock
    class PB_Tokenizer < BaseTokenizer
      @@lexeme2name = {
        '(' => 'LPAREN',
        ')' => 'RPAREN',
        '+' => 'PLUS'
      }.freeze

      protected

      # rubocop: disable Lint/DuplicateBranch
      def recognize_token
        if (lexeme = scanner.scan(/[()]/)) # Single characters
          # Delimiters, separators => single character token
          build_token(@@lexeme2name[lexeme], lexeme)
        elsif (lexeme = scanner.scan(/(?:\+)(?=\s)/)) # Isolated char
          build_token(@@lexeme2name[lexeme], lexeme)
        elsif (lexeme = scanner.scan(/[+-]?[0-9]+/))
          build_token('int', lexeme)
        end
      end
      # rubocop: enable Lint/DuplicateBranch
    end # class
    # rubocop: enable Lint/ConstantDefinitionInBlock

    # Basic tokenizer
    # @return [Array<Rley::Lexical::Token>]
    def tokenize(aText)
      tokenizer = PB_Tokenizer.new(aText)
      tokenizer.tokens
    end

    it 'returns a sequence of tokens' do
      sequence = tokenize(sample_input)
      checks = [
        ['int', 7, [1, 1]],
        ['PLUS', '+', [1, 3]],
        ['LPAREN', '(', [1, 5]],
        ['int', 8, [1, 6]],
        ['PLUS', '+', [1, 8]],
        ['int', 9, [1, 10]],
        ['RPAREN', ')', [1, 11]]
      ]
      sequence.each_with_index do |token, i|
        (tok_type, tok_value, tok_pos) = checks[i]
        (line, col) = tok_pos
        expect(token.terminal).to eq(tok_type)
        expect(token.lexeme).to eq(tok_value.to_s)
        expect(token.position.line).to eq(line)
        expect(token.position.column).to eq(col)
      end
    end
  end
end # describe
