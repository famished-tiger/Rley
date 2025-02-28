# frozen_string_literal: true

require_relative 'spec_helper' # Use the RSpec framework

# Load the class under test
require_relative '../toml_tokenizer'

describe TOMLTokenizer do
  # Utility method for comparing actual and expected token
  # sequence.
  def match_expectations(tokenizer, theExpectations)
    tokens = tokenizer.tokens

    tokens.each_with_index do |token, i|
      terminal, lexeme = theExpectations[i]
      expect(token.terminal).to eq(terminal)
      expect(token.lexeme).to eq(lexeme)
    end
  end

  subject(:tokenizer) { described_class.new }

  let(:sample_text) do
    <<-TOML
    # This is a TOML document

    title = "TOML Example"
TOML
  end

  context 'Initialization:' do
    it 'is initialized with a text to tokenize or...' do
      expect { described_class.new(sample_text) }.not_to raise_error
    end

    it 'is initialized without argument...' do
      expect { described_class.new }.not_to raise_error
    end

    it 'has its scanner initialized' do
      expect(tokenizer.scanner).to be_a(StringScanner)
    end
  end # context

  context 'Data type tokenization:' do
    it 'recognizes single special character token' do
      input = '='
      tokenizer.start_with(input)
      expectations = [
        # [token lexeme]
        %w[EQUAL =]
      ]
      match_expectations(tokenizer, expectations)
    end

    it 'recognizes a boolean literal' do
      [['true', TrueClass], ['false', FalseClass]].each do |(str, klass)|
        tokenizer.start_with(str)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('BOOLEAN')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLBoolean)
        expect(token.value.value).to be_a(klass)
      end
    end

    it 'recognizes an unquoted key' do
      %w[key bare_key bare-key 1234].each do |str|
        tokenizer.start_with(str)
        token_true = tokenizer.tokens[0]
        expect(token_true).to be_a(Rley::Lexical::Literal)
        expect(token_true.terminal).to eq('UNQUOTED-KEY')
        expect(token_true.lexeme).to eq(str)
        expect(token_true.value).to be_a(UnquotedKey)
      end
    end

    it 'recognizes basic strings' do
      str = '"TOML Example"'
      tokenizer.start_with(str)
      token_true = tokenizer.tokens[0]
      expect(token_true).to be_a(Rley::Lexical::Literal)
      expect(token_true.terminal).to eq('STRING')
      expect(token_true.lexeme).to eq(str)
      expect(token_true.value).to be_a(TOMLString)
    end
  end # context

  context 'TOML tokenization:' do
    it 'recognizes a key-value pair' do
      instance = described_class.new(sample_text)
      (key, equal, str) = instance.tokens
      expect(key).to be_a(Rley::Lexical::Literal)
      expect(key.position.line).to eq(3)
      expect(key.position.column).to eq(5)
      expect(key.terminal).to eq('UNQUOTED-KEY')
      expect(key.lexeme).to eq('title')
      expect(key.value).to be_a(UnquotedKey)

      expect(equal).to be_a(Rley::Lexical::Token)
      expect(equal.position.line).to eq(3)
      expect(equal.position.column).to eq(11)
      expect(equal.terminal).to eq('EQUAL')
      expect(equal.lexeme).to eq('=')

      expect(str).to be_a(Rley::Lexical::Literal)
      expect(str.position.line).to eq(3)
      expect(str.position.column).to eq(12) # Position of opening quote
      expect(str.terminal).to eq('STRING')
      expect(str.lexeme).to eq('"TOML Example"')
      expect(str.value).to be_a(TOMLString)
      expect(str.value.value).to eq('TOML Example')
    end
  end # context
end # describe
