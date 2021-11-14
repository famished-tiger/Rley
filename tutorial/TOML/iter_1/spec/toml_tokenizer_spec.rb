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

  let(:sample_text) do
    <<-TOML
    # This is a TOML document

    title = "TOML Example"
TOML
  end
  subject { TOMLTokenizer.new }

  context 'Initialization:' do
    it 'could be initialized with a text to tokenize or...' do
      expect { TOMLTokenizer.new(sample_text) }.not_to raise_error
    end

    it 'could be initialized without argument...' do
      expect { TOMLTokenizer.new }.not_to raise_error
    end

    it 'should have its scanner initialized' do
      expect(subject.scanner).to be_kind_of(StringScanner)
    end

    it 'should be indefault state' do
      expect(subject.state).to eq(:default)
    end
  end # context

  context 'Data type tokenization:' do
    it 'should recognize single special character token' do
      input = '='
      subject.start_with(input)
      expectations = [
        # [token lexeme]
        %w[EQUAL =]
      ]
      match_expectations(subject, expectations)
    end

    it 'should recognize a boolean literal' do
      [['true', TrueClass], ['false', FalseClass]].each do |(str, klass)|
        subject.start_with(str)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('BOOLEAN')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLBoolean)
        expect(token.value.value).to be_kind_of(klass)
      end
    end

    it 'should recognize an unquoted key' do
      %w[key bare_key bare-key 1234].each do |str|
        subject.start_with(str)
        token_true = subject.tokens[0]
        expect(token_true).to be_kind_of(Rley::Lexical::Literal)
        expect(token_true.terminal).to eq('UNQUOTED-KEY')
        expect(token_true.lexeme).to eq(str)
        expect(token_true.value).to be_kind_of(UnquotedKey)
      end
    end

    it 'should recognize basic strings' do
      str = '"TOML Example"'
      subject.start_with(str)
      token_true = subject.tokens[0]
      expect(token_true).to be_kind_of(Rley::Lexical::Literal)
      expect(token_true.terminal).to eq('BASIC-STRING')
      expect(token_true.lexeme).to eq(str)
      expect(token_true.value).to be_kind_of(TOMLString)
    end
  end # context

  context 'TOML tokenization:' do
    it 'should recognize a key-value pair' do
      instance = TOMLTokenizer.new(sample_text)
      (key, equal, str) = instance.tokens
      expect(key).to be_kind_of(Rley::Lexical::Literal)
      expect(key.position.line).to eq(3)
      expect(key.position.column).to eq(5)
      expect(key.terminal).to eq('UNQUOTED-KEY')
      expect(key.lexeme).to eq('title')
      expect(key.value).to be_kind_of(UnquotedKey)

      expect(equal).to be_kind_of(Rley::Lexical::Token)
      expect(equal.position.line).to eq(3)
      expect(equal.position.column).to eq(11)
      expect(equal.terminal).to eq('EQUAL')
      expect(equal.lexeme).to eq('=')

      expect(str).to be_kind_of(Rley::Lexical::Literal)
      expect(str.position.line).to eq(3)
      expect(str.position.column).to eq(13)
      expect(str.terminal).to eq('BASIC-STRING')
      expect(str.lexeme).to eq('"TOML Example"')
      expect(str.value).to be_kind_of(TOMLString)
      expect(str.value.value).to eq('TOML Example')
    end
  end # context
end # describe
