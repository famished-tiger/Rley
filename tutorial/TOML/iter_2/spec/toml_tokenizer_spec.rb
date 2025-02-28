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

    it 'is in default state' do
      expect(tokenizer.state).to eq(:default)
    end
  end # context

  context 'Separator and delimiters tokenization:' do
    it 'recognizes single special character token' do
      cases = [
        # token, lexeme
        %w(COMMA ,),
        %w(EQUAL =),
        %w(LBRACKET [),
        %w(RBRACKET ])
      ]
      cases.each do |(token, lexeme)|
        tokenizer.start_with(lexeme)
        expectations = [[token, lexeme]]
        match_expectations(tokenizer, expectations)
      end
    end
  end # context

  context 'Data type tokenization:' do
    it 'recognizes a boolean literal' do
      [['true', TrueClass], ['false', FalseClass]].each do |(str, klass)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('BOOLEAN')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLBoolean)
        expect(token.value.value).to be_a(klass)
      end
    end

    it 'recognizes decimal integer literals' do
      stack = tokenizer.instance_variable_get(:@keyval_stack)
      stack[-1] = 2

      cases = [
        # token,      lexeme
        ['+99',       99],
        ['42',        42],
        ['0',         0],
        ['+0',        0],
        ['-0',        0],
        ['-17',       -17],
        ['1_000',     1000],
        ['5_349_221', 5_349_221],
        ['53_49_221', 5_349_221],
        ['1_2_3_4_5', 12345]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        int_token = tokenizer.tokens[0]
        expect(int_token).to be_a(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_a(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'recognizes hexadecimal integer literals' do
      stack = tokenizer.instance_variable_get(:@keyval_stack)
      stack[-1] = 2

      cases = [
        # token, lexeme
        ['0xDEADBEEF',  0xdeadbeef],
        ['0xdeadbeef',  0xdeadbeef],
        ['0xdead_beef', 0xdeadbeef],
        ['0x0', 0]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        int_token = tokenizer.tokens[0]
        expect(int_token).to be_a(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_a(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'recognizes octal integer literals' do
      stack = tokenizer.instance_variable_get(:@keyval_stack)
      stack[-1] = 2

      cases = [
        # token,       lexeme
        ['0o01234567', 0o01234567],
        ['0o755',      0o755],
        ['0o0',        0]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        int_token = tokenizer.tokens[0]
        expect(int_token).to be_a(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_a(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'recognizes binary integer literals' do
      stack = tokenizer.instance_variable_get(:@keyval_stack)
      stack[-1] = 2

      cases = [
        # token,       lexeme
        ['0b11010110', 0b11010110],
        ['0b0',        0]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        int_token = tokenizer.tokens[0]
        expect(int_token).to be_a(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_a(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'recognizes float literals' do
      cases = [
        # token,       lexeme
        ['+1.0', 1.0],
        ['3.1415', 3.1415],
        ['-0.01', -0.01],
        ['5e+22', 5e+22],
        ['1e06', 1e06],
        ['-2E-2', -2e-2],
        ['6.626e-34', 6.626e-34],
        ['224_617.445_991_228', 224617.445991228]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        float_token = tokenizer.tokens[0]
        expect(float_token).to be_a(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_a(TOMLFloat)
        expect(float_token.value.value).to eq(val)
      end
    end

    it 'recognizes infinite float literals' do
      cases = [
        # token,       lexeme
        ['inf', Float::INFINITY],
        ['+inf', Float::INFINITY],
        ['-inf', -Float::INFINITY]
      ]
      cases.each do |(str, val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        float_token = tokenizer.tokens[0]
        expect(float_token).to be_a(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_a(TOMLFloat)
        expect(float_token.value.value).to eq(val)
      end
    end

    it 'recognizes NaN float literals' do
      cases = [
        # token,       lexeme
        ['nan', Float::NAN],
        ['+nan', Float::NAN],
        ['-nan', -Float::NAN]
      ]
      cases.each do |(str, _val)|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        float_token = tokenizer.tokens[0]
        expect(float_token).to be_a(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_a(TOMLFloat)
        expect(float_token.value.value).to be_nan
      end
    end

    it 'recognizes an unquoted key' do
      %w[key bare_key bare-key 1234].each do |str|
        tokenizer.start_with(str)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('UNQUOTED-KEY')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(UnquotedKey)
      end
    end

    it 'recognizes literal strings' do
      cases = [
        "''",
        "'TOML Example'",
        "'# This is not a comment'",
        "'C:\\Users\\nodejs\\templates'",
        "'\\\\ServerX\\admin$\\system32\\'",
        "'Tom \"Dubs\" Preston-Werner'",
        "'<\\i\\c*\\s*>'"
      ]
      cases.each do |str|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLString)
        expect(token.value.value).to eq(str[1..-2]) # Remove delimiters
      end
    end

    it 'recognizes single line triple quotes strings' do
      cases = [
        "''''''",
        "'''TOML Example'''",
        "'''# This is not a comment'''",
        "'''It's tea time'''",
        "'''C:\\Users\\nodejs\\templates'''",
        "'''\\\\ServerX\\admin$\\system32\\'''",
        "'''Tom \"Dubs\" Preston-Werner'''",
        "'''<\\i\\c*\\s*>'''"
      ]
      cases.each do |str|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLString)
        expect(token.value.value).to eq(str[3..-4]) # Remove delimiters
      end
    end

    it 'recognizes multi-line triple quotes strings' do
      str = <<-TOML
'''
The first newline is
trimmed in raw strings.
   All other whitespace
   is preserved.
'''
      TOML
      tokenizer.start_with(str)
      tokenizer.send(:equal_found)
      token = tokenizer.tokens[0]
      expect(token).to be_a(Rley::Lexical::Literal)
      expect(token.terminal).to eq('STRING')
      expected_lexeme = str.chomp
      expect(token.lexeme).to eq(expected_lexeme)
      expect(token.value).to be_a(TOMLString)
      expected_value = str.gsub(/(?:^'''\n*|'''\n*$)/, '')
      expect(token.value.value).to eq(expected_value) # Remove delimiters
    end

    it 'recognizes basic strings' do
      cases = [
        # ['""', ''],
        # ['"TOML Example"', 'TOML Example'],
        # ['"# This is not a comment"', '# This is not a comment'],
        ['"\b\t\n\f\r\"\u007b\U0000007D"', "\b\t\n\f\r\"{}"]
      ]
      cases.each do |str, expected|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLString)
        expect(token.value.value).to eq(expected) # Remove delimiters
      end
    end

    it 'recognizes single line triple double quotes strings' do
      cases = [
        ['  """"""  ', ''],
        ['"""TOML Example"""', 'TOML Example'],
        ['"""# This is not a comment"""', '# This is not a comment'],
        ['"""\b\t\n\f\r\"\u007b\U0000007D"""', "\b\t\n\f\r\"{}"]
      ]
      cases.each do |str, expected|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str.strip)
        expect(token.value).to be_a(TOMLString)
        expect(token.value.value).to eq(expected) # Remove delimiters
      end
    end

    it 'recognizes unescaped basic multi-line strings' do
      str1 = '"The quick brown fox jumps over the lazy dog."'
      str2 = <<-'TOML'
      """The quick brown \


      fox jumps over \
        the lazy dog."""
      TOML

      str3 = <<-'TOML'
       """\
       The quick brown \
       fox jumps over \
       the lazy dog.\
      """
      TOML
      [str2, str3].each do |str|
        tokenizer.start_with(str)
        tokenizer.send(:equal_found)
        token = tokenizer.tokens[0]
        expect(token).to be_a(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        # expect(token.lexeme).to eq(str)
        expect(token.value).to be_a(TOMLString)
        expect(token.value.value).to eq(str1[1..-2])
      end
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
      expect(str.position.column).to eq(13) # Position of opening quote
      expect(str.terminal).to eq('STRING')
      expect(str.lexeme).to eq('"TOML Example"')
      expect(str.value).to be_a(TOMLString)
      expect(str.value.value).to eq('TOML Example')
    end
  end # context
end # describe
