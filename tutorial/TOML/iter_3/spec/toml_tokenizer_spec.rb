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

    it 'should be in default state' do
      expect(subject.state).to eq(:default)
    end
  end # context

  context 'Separator and delimiters tokenization:' do
    it 'should recognize single stateless character in default state' do
      cases = [
        # token, lexeme
        %w(COMMA ,),
        %w(DOT .),
        %w(LBRACKET [),
        %w(RBRACKET ])
      ]
      cases.each do |(token, lexeme)|
        subject.start_with(lexeme)
        expectations = [[token, lexeme]]
        match_expectations(subject, expectations)
        expect(subject.state).to eq(:default)
      end
    end

    it 'should recognize equal character in default state' do
      cases = [
        # token, lexeme
        %w(EQUAL =)
      ]
      cases.each do |(token, lexeme)|
        subject.start_with(lexeme)
        expectations = [[token, lexeme]]
        match_expectations(subject, expectations)
        expect(subject.state).to eq(:expecting_value)
      end
    end

      # it 'should recognize single special character in expecting value state' do
      #   cases = [
      #     # token, lexeme
      #     %w(COMMA ,),
      #     %w(LBRACKET [),
      #     %w(RBRACKET ]),
      #   ]
      #   cases.each do |(token, lexeme)|
      #     subject.start_with(lexeme)
      #     subject.send(:equal_found)
      #     expectations = [[token, lexeme]]
      #     match_expectations(subject, expectations)
      #     expect(subject.state).to eq(:expecting_value)
      #   end
      # end
  end # context

  context 'Data type tokenization:' do
    it 'should recognize a boolean literal' do
      [['true', TrueClass], ['false', FalseClass]].each do |(str, klass)|
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('BOOLEAN')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLBoolean)
        expect(token.value.value).to be_kind_of(klass)
      end
    end

    it 'should recognize decimal integer literals' do
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
        subject.start_with(str)
        subject.send(:equal_found)
        int_token = subject.tokens[0]
        expect(int_token).to be_kind_of(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_kind_of(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'should recognize hexadecimal integer literals' do
      cases = [
        # token, lexeme
        ['0xDEADBEEF',  0xdeadbeef],
        ['0xdeadbeef',  0xdeadbeef],
        ['0xdead_beef', 0xdeadbeef],
        ['0x0',         0],
        ['0x00',        0],
        ['0x0000',      0]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        int_token = subject.tokens[0]
        expect(int_token).to be_kind_of(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_kind_of(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'should recognize octal integer literals' do
      cases = [
        # token,       lexeme
        ['0o01234567', 0o01234567],
        ['0o755',      0o755],
        ['0o7_6_5',    0o765],
        ['0o0',        0],
        ['0o00',       0],
        ['0o0000',     0]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        int_token = subject.tokens[0]
        expect(int_token).to be_kind_of(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_kind_of(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'should recognize binary integer literals' do
      cases = [
        # token,       lexeme
        ['0b11010110', 0b11010110],
        ['0b1_0_1',    0b101],
        ['0b0',        0],
        ['0b00',       0],
        ['0b0000',     0]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        int_token = subject.tokens[0]
        expect(int_token).to be_kind_of(Rley::Lexical::Literal)
        expect(int_token.terminal).to eq('INTEGER')
        expect(int_token.lexeme).to eq(str)
        expect(int_token.value).to be_kind_of(TOMLInteger)
        expect(int_token.value.value).to eq(val)
      end
    end

    it 'should recognize float literals' do
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
        subject.start_with(str)
        subject.send(:equal_found)
        float_token = subject.tokens[0]
        expect(float_token).to be_kind_of(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_kind_of(TOMLFloat)
        expect(float_token.value.value).to eq(val)
      end
    end

    it 'should recognize infinite float literals' do
      cases = [
        # token,       lexeme
        ['inf', Float::INFINITY],
        ['+inf', Float::INFINITY],
        ['-inf', -Float::INFINITY]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        float_token = subject.tokens[0]
        expect(float_token).to be_kind_of(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_kind_of(TOMLFloat)
        expect(float_token.value.value).to eq(val)
      end
    end

    it 'should recognize NaN float literals' do
      cases = [
        # token,       lexeme
        ['nan', Float::NAN],
        ['+nan', Float::NAN],
        ['-nan', -Float::NAN]
      ]
      cases.each do |(str, _val)|
        subject.start_with(str)
        subject.send(:equal_found)
        float_token = subject.tokens[0]
        expect(float_token).to be_kind_of(Rley::Lexical::Literal)
        expect(float_token.terminal).to eq('FLOAT')
        expect(float_token.lexeme).to eq(str)
        expect(float_token.value).to be_kind_of(TOMLFloat)
        expect(float_token.value.value).to be_nan
      end
    end

    it 'should recognize offset date time' do
      str = '1979-05-27T05:32:07.999999-07:00'
      subject.start_with(str)
      subject.send(:equal_found)
      date_token = subject.tokens[0]
      expect(date_token).to be_kind_of(Rley::Lexical::Literal)
      expect(date_token.terminal).to eq('OFFSET-DATE-TIME')
      expect(date_token.lexeme).to eq(str)
      expect(date_token.value).to be_kind_of(TOMLOffsetDateTime)
      # expect(date_token.value.value).to eq(val)
    end

    it 'should recognize local date time' do
      cases = [
        # lexeme,       value
        ['1979-05-27T07:32:00', Time.local(1979, 5, 27, 7, 32, 0)],
        ['1979-05-27T00:32:00.999999', Time.local(1979, 5, 27, 0, 32, 0, 999999)]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        date_token = subject.tokens[0]
        expect(date_token).to be_kind_of(Rley::Lexical::Literal)
        expect(date_token.terminal).to eq('LOCAL-DATE-TIME')
        expect(date_token.lexeme).to eq(str)
        expect(date_token.value).to be_kind_of(TOMLLocalDateTime)
        expect(date_token.value.value).to eq(val)
      end
    end

    it 'should recognize local date' do
      cases = [
        # lexeme,       value
        ['1979-05-27', Date.new(1979, 5, 27)],
        ['2000-02-29', Date.new(2000, 2, 29)]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        date_token = subject.tokens[0]
        expect(date_token).to be_kind_of(Rley::Lexical::Literal)
        expect(date_token.terminal).to eq('LOCAL-DATE')
        expect(date_token.lexeme).to eq(str)
        expect(date_token.value).to be_kind_of(TOMLLocalDate)
        expect(date_token.value.value).to eq(val)
      end
    end

    it 'should recognize local time' do
      cases = [
        # lexeme,       value
        ['07:32:00', [7, 32, 0, 0]],
        ['07:32:00.999999', [7, 32, 0, 999999]]
      ]
      cases.each do |(str, val)|
        subject.start_with(str)
        subject.send(:equal_found)
        time_token = subject.tokens[0]
        expect(time_token).to be_kind_of(Rley::Lexical::Literal)
        expect(time_token.terminal).to eq('LOCAL-TIME')
        expect(time_token.lexeme).to eq(str)
        expect(time_token.value).to be_kind_of(TOMLLocalTime)
        (hour, min, sec, usec) = val
        expect(time_token.value.hour).to eq(hour)
        expect(time_token.value.min).to eq(min)
        expect(time_token.value.sec).to eq(sec)
        expect(time_token.value.usec).to eq(usec)
      end
    end

    it 'should recognize literal strings' do
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
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLString)
        expect(token.value.value).to eq(str[1..-2]) # Remove delimiters
      end
    end

    it 'should recognize single line triple quotes strings' do
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
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLString)
        expect(token.value.value).to eq(str[3..-4]) # Remove delimiters
      end
    end

    it 'should recognize multi-line triple quotes strings' do
      str = <<-TOML
'''
The first newline is
trimmed in raw strings.
   All other whitespace
   is preserved.
'''
      TOML
      subject.start_with(str)
      subject.send(:equal_found)
      token = subject.tokens[0]
      expect(token).to be_kind_of(Rley::Lexical::Literal)
      expect(token.terminal).to eq('STRING')
      expected_lexeme = str.chomp
      expect(token.lexeme).to eq(expected_lexeme)
      expect(token.value).to be_kind_of(TOMLString)
      expected_value = str.gsub(/(?:^'''\n*|'''\n*$)/, '')
      expect(token.value.value).to eq(expected_value) # Remove delimiters
    end

    it 'should recognize basic strings' do
      cases = [
        # ['""', ''],
        # ['"TOML Example"', 'TOML Example'],
        # ['"# This is not a comment"', '# This is not a comment'],
        ['"\b\t\n\f\r\"\u007b\U0000007D"', "\b\t\n\f\r\"{}"]
      ]
      cases.each do |str, expected|
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLString)
        expect(token.value.value).to eq(expected) # Remove delimiters
      end
    end

    it 'should recognize single line triple double quotes strings' do
      cases = [
        ['  """"""  ', ''],
        ['"""TOML Example"""', 'TOML Example'],
        ['"""# This is not a comment"""', '# This is not a comment'],
        ['"""\b\t\n\f\r\"\u007b\U0000007D"""', "\b\t\n\f\r\"{}"]
      ]
      cases.each do |str, expected|
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        expect(token.lexeme).to eq(str.strip)
        expect(token.value).to be_kind_of(TOMLString)
        expect(token.value.value).to eq(expected) # Remove delimiters
      end
    end

    it 'should recognize unescaped basic multi-line strings' do
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
        subject.start_with(str)
        subject.send(:equal_found)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('STRING')
        # expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(TOMLString)
        expect(token.value.value).to eq(str1[1..-2])
      end
    end
  end # context

  context 'TOML tokenization in default state:' do
    def next_token(tokenizer, lexeme, terminal, klass = nil)
      token = tokenizer.send(:_next_token)
      expect(token.lexeme).to eq(lexeme)
      expect(token.terminal).to eq(terminal)
      expect(token.value).to be_kind_of(klass) if klass
    end

    it 'should recognize an unquoted key' do
      %w[key bare_key bare-key true 1234].each do |str|
        subject.start_with(str)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('UNQUOTED-KEY')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(UnquotedKey)
      end
    end

    it 'should recognize a quoted key' do
      cases = [
        '"127.0.0.1"',
        '"character encoding"',
        "'key2'",
        %q|'quoted "value"'|,
        '""',
        "''"
      ]
      cases.each do |str|
        subject.start_with(str)
        token = subject.tokens[0]
        expect(token).to be_kind_of(Rley::Lexical::Literal)
        expect(token.terminal).to eq('QUOTED-KEY')
        expect(token.lexeme).to eq(str)
        expect(token.value).to be_kind_of(QuotedKey)
        expect(token.value.value).to eq(str[1..-2])
      end
    end

    it 'should recognize a dotted key' do
      cases = [
        'physical.color',
        'physical.shape',
        'site."google"'
      ]
      cases.each do |str|
        subject.start_with(str)
        (left, dot, right) = subject.tokens
        (left_lex, right_lex) = str.split('.')
        expect(left).to be_kind_of(Rley::Lexical::Literal)
        expect(left.terminal).to eq('UNQUOTED-KEY')
        expect(left.lexeme).to eq(left_lex)
        expect(left.value).to be_kind_of(UnquotedKey)
        expect(left.value.value).to eq(left_lex)

        expect(dot).to be_kind_of(Rley::Lexical::Token)
        expect(dot.terminal).to eq('DOT')

        expect(right).to be_kind_of(Rley::Lexical::Literal)
        expect(right.terminal).to match(/QUOTED-KEY$/)
        expect(right.lexeme).to eq(right_lex)
        expect(right.value.value).to eq(right_lex.gsub(/"/, ''))
      end
    end

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
      expect(str.position.column).to eq(13) # Position of opening quote
      expect(str.terminal).to eq('STRING')
      expect(str.lexeme).to eq('"TOML Example"')
      expect(str.value).to be_kind_of(TOMLString)
      expect(str.value.value).to eq('TOML Example')
    end

    it 'should recognize a dotted table name' do
      source = '[server."alpha"]'
      # TOS     00     00      0
      instance = TOMLTokenizer.new(source)
      next_token(instance, '[', 'LBRACKET')
      expect(instance.state).to eq(:default)

      next_token(instance, 'server', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)

      next_token(instance, '.', 'DOT')
      expect(instance.state).to eq(:default)

      next_token(instance, '"alpha"', 'QUOTED-KEY', QuotedKey)
      expect(instance.state).to eq(:default)

      next_token(instance, ']', 'RBRACKET')
      expect(instance.state).to eq(:default)
    end

    it 'should recognize array of literals' do
      source = 'ports = [ 8000, 8001, 8002 ]'
      # TOS     0     1 2 2   2 2   2 2    0
      instance = TOMLTokenizer.new(source)
      next_token(instance, 'ports', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1])

      next_token(instance, '[', 'LBRACKET')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, '8000', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, ',', 'COMMA')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, '8001', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, ',', 'COMMA')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, '8002', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([2])

      next_token(instance, ']', 'RBRACKET')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([0])
    end

    it 'should recognize inline tables' do
      source = 'temp_targets = { cpu = 79.5, "case" = 72.0 }'
      # TOS     0            1 0 0   1 0   0 0      1 1    0
      # TOS-1   -            - 1 1   1 1   1 1      1 1
      instance = TOMLTokenizer.new(source)
      next_token(instance, 'temp_targets', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1])

      next_token(instance, '{', 'LACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, 'cpu', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 1])

      next_token(instance, '79.5', 'FLOAT', TOMLFloat)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, ',', 'COMMA')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '"case"', 'QUOTED-KEY', QuotedKey)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 1])

      next_token(instance, '72.0', 'FLOAT', TOMLFloat)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '}', 'RACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([0])
    end

    it 'should recognize nested aggregates' do
      source = "key = { a = [1, [2]], b = { 'c' = 3 }}"
      # TOS     0   1 0 0 1 222 33200 0 1 0 0   1 0 0
      # TOS-1   -   - 1 1 1 111 11111 1 1 1 1   1 1 1
      # TOS-2                             1 1   1 1
      instance = TOMLTokenizer.new(source)
      next_token(instance, 'key', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1])

      next_token(instance, '{', 'LACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, 'a', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 1])

      next_token(instance, '[', 'LBRACKET')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 2])

      next_token(instance, '1', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 2])

      next_token(instance, ',', 'COMMA')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 2])

      next_token(instance, '[', 'LBRACKET')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 3])

      next_token(instance, '2', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 3])

      next_token(instance, ']', 'RBRACKET')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 2])

      next_token(instance, ']', 'RBRACKET')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, ',', 'COMMA')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, 'b', 'UNQUOTED-KEY', UnquotedKey)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 1])

      next_token(instance, '{', 'LACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 1, 0])

      next_token(instance, "'c'", 'QUOTED-KEY', QuotedKey)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 1, 0])

      next_token(instance, '=', 'EQUAL')
      expect(instance.state).to eq(:expecting_value)
      expect(instance.keyval_stack).to eq([1, 1, 1])

      next_token(instance, '3', 'INTEGER', TOMLInteger)
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 1, 0])

      next_token(instance, '}', 'RACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([1, 0])

      next_token(instance, '}', 'RACCOLADE')
      expect(instance.state).to eq(:default)
      expect(instance.keyval_stack).to eq([0])
    end
  end # context
end # describe
