# frozen_string_literal: true

require 'strscan'
require 'rley'
require_relative 'toml_datatype'

# A tokenizer for a very limited subset of TOML.
# Responsibilities:
#   - read characters from input string ...
#   - and transform them into a sequence of token objects.
class TOMLTokenizer
  PATT_BOOLEAN = /true|false/.freeze
  PATT_CHAR_SINGLE_KEY = /[,.=\[\]}]/.freeze # Single delimiter or separator character
  PATT_CHAR_SINGLE_VAL = /[,\[\]{]/.freeze # Single delimiter or separator character
  PATT_COMMENT = /#[^\r\n]*/.freeze
  PATT_FLOAT = /[-+]? # Optional sign
    (?:0|(?:[1-9](?:(?:_\d)|\d)*)) # Integer part
    (?:
      ((?: \. (?:[0-9](?:(?:_\d)|\d)*)) (?:[eE][-+]?\d+)?) # fractional part with optional exponent part
      |  (?:[eE][-+]?\d+))/x.freeze # or exponent part
  PATT_FLOAT_SPECIAL = /[-+]?(?:inf|nan)/.freeze
  PATT_INT_DEC = /[-+]?(?:0|(?:[1-9](?:(?:_\d)|\d)*))(?!\.)/.freeze
  PATT_INT_HEX = /0x[0-9A-Fa-f](?:(?:_[0-9A-Fa-f])|[0-9A-Fa-f])*/.freeze
  PATT_INT_OCT = /0o[0-7](?:(?:_[0-7])|[0-7])*/.freeze
  PATT_INT_BIN = /0b[01](?:(?:_[01])|[01])*/.freeze
  PATT_KEY_UNQUOTED = /[A-Za-z0-9\-_]+/.freeze
  PATT_KEY_QUOTED_DELIM = /(?:"(?!""))|(?:'(?!''))/.freeze
  PATT_OFFSET_DATE_TIME = /[0-2]\d{3}-[01]\d-[0-3]\d[Tt ][0-2]\d:[0-5]\d:[0-6]\d(?:\.\d+)?(?:[Zz]|(?:[-+][0-6]\d:[0-6]\d))/.freeze
  PATT_LOCAL_DATE_TIME = /[0-2]\d{3}-[01]\d-[0-3]\d[Tt ][0-2]\d:[0-5]\d:[0-6]\d(?:\.\d+)?/.freeze
  PATT_LOCAL_DATE = /[0-2]\d{3}-[01]\d-[0-3]\d/.freeze
  PATT_LOCAL_TIME = /[0-2]\d:[0-5]\d:[0-6]\d(?:\.\d+)?/.freeze
  PATT_NEWLINE = /(?:\r\n)|\r|\n/.freeze
  PATT_STRING_DELIM = /(?:'(?:'')?)|(?:"(?:"")?)/.freeze
  PATT_STRING_ESCAPE = /\\(?:[^Uu]|u[0-9A-Fa-f]{0,4}|U[0-9A-Fa-f]{0,8})/.freeze
  PATT_STRING_END_LITERAL = /(?:[^']|(?:'(?!''))|(?:''(?!')))*?(?:'''|$)/.freeze
  PATT_STRING_END_ML_BASIC = /(?:[^"\\]
    | (?:"(?!""))
    | (?:""[^"\n\r])
    | (?:\\+"?[^"\n\r])
    | (?:\\(?=\n|\r))
    | (?:(\\\\)+\\"""))*?
    (?:"""|$)/x.freeze
  PATT_WHITESPACE = /[ \t\f]+/.freeze
  # @return [StringScanner] Low-level input scanner
  attr_reader(:scanner)

  # Key track of whether the scanner expects a key or avalue
  # This is necessary since the lexeme 1234 can be a naked key or an integer
  # @return [Array<Integer>]
  attr_accessor(:keyval_stack)

  # @return [Integer] The current line number
  attr_reader(:lineno)

  # @return [Integer] Position of last start of line in the input string
  attr_reader(:line_start)

  # Single special character tokens.
  @@lexeme2name = {
    ',' => 'COMMA',
    '.' => 'DOT',
    '=' => 'EQUAL',
    '[' => 'LBRACKET',
    ']' => 'RBRACKET',
    '{' => 'LACCOLADE',
    '}' => 'RACCOLADE'
  }.freeze

  # Single character that have a special meaning when escaped
  # @return [{Char => String}]
  @@escape_chars = {
    ?b => "\b",
    ?f => "\f",
    ?n => "\n",
    ?r => "\r",
    ?t => "\t",
    ?" => ?",
    ?\ => ?\
  }.freeze

  # Constructor. Initialize a tokenizer for Lox input.
  # @param source [String] Lox text to tokenize.
  def initialize(source = nil)
    reset
    input = source || ''
    @scanner = StringScanner.new(input)
  end

  # Reset the tokenizer and make the given text, the current input.
  # @param source [String] Lox text to tokenize.
  def start_with(source)
    reset
    @scanner.string = source
  end

  # Return the current lexical state
  # State can be one of:
  # :default # expecting a key, a table name or equal sign
  # :expecting_value # expecting a value to associate with a key
  # :multiline # Processing a multiline string
  def state
    return :expecting_value if @state == :default && expecting_value?

    @state
  end

  # Scan the source and return an array of tokens.
  # @return [Array<Rley::Lexical::Token>] | Returns a sequence of tokens
  def tokens
    tok_sequence = []
    until @scanner.eos?
      token = _next_token
      tok_sequence << token unless token.nil?
    end

    tok_sequence
  end

  private

  def reset
    @state = :default
    @keyval_stack = [0]
    @lineno = 1
    @line_start = 0
  end

  # rubocop: disable Metrics/MethodLength
  def _next_token
    token = nil

    # Loop until end of input reached or token found
    until scanner.eos? || token
      nl_found = scanner.skip(PATT_NEWLINE)
      if nl_found
        next_line_scanned
        next
      end

      unless state == :multiline
        # Code common to :default and :expecting_value states
        next if scanner.skip(PATT_WHITESPACE) # Skip whitespaces

        curr_ch = scanner.peek(1)

        if curr_ch == '#'
          # Start of comment detected...
          scanner.skip(PATT_COMMENT) # Skip line comment
          next
        end
      end

      token = case state
        when :default
          if (lexeme = scanner.scan(PATT_KEY_QUOTED_DELIM))
            # Start of quoted key detected...
            begin_string_token(lexeme, :key)
          elsif (lexeme = scanner.scan(PATT_CHAR_SINGLE_KEY))
            build_token(@@lexeme2name[lexeme], lexeme)
          elsif (lexeme = scanner.scan(PATT_KEY_UNQUOTED))
            build_literal('UNQUOTED-KEY', lexeme, UnquotedKey)
          else # Unknown token
            col = scanner.pos - @line_start + 1
            erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
            raise ScanError, "Error: [line #{lineno}:#{col}]: Unexpected character #{erroneous}."
          end

        when :expecting_value
          if (lexeme = scanner.scan(PATT_STRING_DELIM))
            # Start of string detected...
            string_token = begin_string_token(lexeme, :string)
            next if state == :multiline

            update_keyval_state(string_token)
            string_token
          elsif (lexeme = scanner.scan(PATT_CHAR_SINGLE_VAL))
            build_token(@@lexeme2name[lexeme], lexeme)
          elsif (lexeme = scanner.scan(PATT_BOOLEAN))
            build_literal('BOOLEAN', lexeme, TOMLBoolean)
          elsif (lexeme = scanner.scan(PATT_OFFSET_DATE_TIME))
            build_literal('OFFSET-DATE-TIME', lexeme, TOMLOffsetDateTime)
          elsif (lexeme = scanner.scan(PATT_LOCAL_DATE_TIME))
            build_literal('LOCAL-DATE-TIME', lexeme, TOMLLocalDateTime)
          elsif (lexeme = scanner.scan(PATT_LOCAL_DATE))
            build_literal('LOCAL-DATE', lexeme, TOMLLocalDate)
          elsif (lexeme = scanner.scan(PATT_LOCAL_TIME))
            build_literal('LOCAL-TIME', lexeme, TOMLLocalTime)
          elsif (lexeme = scanner.scan(PATT_FLOAT))
            build_literal('FLOAT', lexeme, TOMLFloat)
          elsif (lexeme = scanner.scan(PATT_INT_HEX))
            build_literal('INTEGER', lexeme, TOMLInteger, :hex)
          elsif (lexeme = scanner.scan(PATT_INT_OCT))
            build_literal('INTEGER', lexeme, TOMLInteger, :oct)
          elsif (lexeme = scanner.scan(PATT_INT_BIN))
            build_literal('INTEGER', lexeme, TOMLInteger, :bin)
          elsif (lexeme = scanner.scan(PATT_INT_DEC))
            build_literal('INTEGER', lexeme, TOMLInteger)
          elsif (lexeme = scanner.scan(PATT_FLOAT_SPECIAL))
            build_special_float(lexeme)
          else # Unknown token
            col = scanner.pos - @line_start + 1
            erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
            raise ScanError, "Error: [line #{lineno}:#{col}]: Unexpected character #{erroneous}."
          end

        when :multiline
          add_next_line
          next if @state == :multiline

          string_token = build_multiline_string
          update_keyval_state(string_token)
          string_token
      end # case state
    end # until

    unterminated(@string_start.line, @string_start.column) if state == :multiline
    token
  end
  # rubocop: enable Metrics/MethodLength

  # Is the tokenizer expecting a data value?
  # ToS keyval_stack == 0 => false (:default state)
  # ToS keyval_stack > 0 => true (:expecting_value state)
  def expecting_value?
    @keyval_stack.last.positive?
  end

  def build_token(aSymbolName, aLexeme)
    begin
      lex_length = aLexeme ? aLexeme.size : 0
      col = scanner.pos - lex_length - @line_start + 1
      pos = Rley::Lexical::Position.new(@lineno, col)
      token = Rley::Lexical::Token.new(aLexeme.dup, aSymbolName, pos)
    rescue StandardError => e
      puts "Failing with '#{aSymbolName}' and '#{aLexeme}'"
      raise e
    end

    update_keyval_state(token)
    token
  end

  def build_special_float(aLexeme)
    lex_length = aLexeme ? aLexeme.size : 0
    col = scanner.pos - lex_length - @line_start + 1
    pos = Rley::Lexical::Position.new(@lineno, col)
    value = case aLexeme
      when 'inf', '+inf'
        TOMLFloat::INFINITY
      when '-inf'
        TOMLFloat::INFINITY_MIN
      when 'nan', '+nan'
        TOMLFloat::NAN
      when '-nan'
        TOMLFloat::NAN_MIN
    end
    token = Rley::Lexical::Literal.new(value, aLexeme.dup, 'FLOAT', pos)
    update_keyval_state(token)
    token
  end

  def build_literal(aSymbolName, aLexeme, aClass, aFormat = nil)
    value = aClass.new(aLexeme, aFormat)
    lex_length = aLexeme ? aLexeme.size : 0
    col = scanner.pos - lex_length - @line_start + 1
    pos = Rley::Lexical::Position.new(@lineno, col)
    literal = Rley::Lexical::Literal.new(value, aLexeme.dup, aSymbolName, pos)

    update_keyval_state(literal)
    literal
  end

  # precondition: current position at leading delimiter
  def begin_string_token(delimiter, token_type)
    @scan_pos = scanner.pos
    line = @lineno
    column_start = @scan_pos - @line_start
    @string_start = Rley::Lexical::Position.new(line, column_start)

    case delimiter
    when "'"
      literal = scanner.scan(/[^']*'/)
      unterminated(line, column_start) unless literal
      lexeme = scanner.string[(@scan_pos - 1)..scanner.pos - 1]
      if token_type == :key
        token_kind = 'QUOTED-KEY'
        token_value = QuotedKey.new(literal[0..-2])
      else
        token_kind = 'STRING'
        token_value = TOMLString.new(literal[0..-2])
      end
      Rley::Lexical::Literal.new(token_value, lexeme, token_kind, @string_start)

    when '"'
      literal = scanner.scan(/(?:[^"]|(?:(?<=\\)"))*"/)
      unterminated(line, column_start) unless literal
      raw_value = literal[0..-2]
      lexeme = scanner.string[(@scan_pos - 1)..scanner.pos - 1]
      if token_type == :key
        token_kind = 'QUOTED-KEY'
        token_value = QuotedKey.new(unescape(raw_value))
      else
        token_kind = 'STRING'
        token_value = TOMLString.new(unescape(raw_value))
      end
      Rley::Lexical::Literal.new(token_value, lexeme, token_kind, @string_start)

    when "'''"
      literal = scanner.scan(PATT_STRING_END_LITERAL)
      unterminated(line, column_start) unless literal
      if literal =~ /'''$/
        # ... single-line string
        string_value = TOMLString.new(literal[0..-4])
        lexeme = scanner.string[(@scan_pos - 3)..scanner.pos - 1]
        Rley::Lexical::Literal.new(string_value, lexeme, 'STRING', @string_start)
      else
        # ... multi-line lliteral string
        @state = :multiline
        @string_delimiter = delimiter
        @multilines = literal.empty? ? [] : [literal, "\n"]
      end
    when '"""'
      literal = scanner.scan(PATT_STRING_END_ML_BASIC)
      unterminated(line, column_start) unless literal
      if literal.slice!(/"""$/)
        # ... single-line string
        string_value = TOMLString.new(unescape(literal))
        lexeme = scanner.string[(@scan_pos - 3)..scanner.pos - 1]
        Rley::Lexical::Literal.new(string_value, lexeme, 'STRING', @string_start)
      else
        # ... multi-line literal string
        @state = :multiline
        @string_delimiter = delimiter
        if literal.empty?
          @multilines = []
        else
          if literal =~ /(?:\\)*\\\s*$/
            literal.rstrip!
            literal.chop!
            @trimming = true
          end
          @multilines = literal.empty? ? [] : [unescape(literal)]
          @multilines << "\n" unless @trimming
        end
      end
    end
  end

  def add_next_line
    if @string_delimiter == "'''"
      literal = scanner.scan(PATT_STRING_END_LITERAL)
      unterminated(line, column_start) unless literal
      if literal.slice!(/'''$/)
        # ... end demimiter found
        @state = :default
        @multilines << literal
      else
        @multilines.concat([literal, "\n"])
      end
    else # ... """
      literal = scanner.scan(PATT_STRING_END_ML_BASIC)
      unterminated(line, column_start) unless literal
      literal.lstrip! if @trimming
      return if @trimming && literal.empty?

      if literal.slice!(/"""$/)
        # ... end demimiter found
        @state = :default
        @multilines << unescape(literal) unless @trimming && literal.empty?
        @trimming = false
      else
        @trimming = false unless literal.empty?
        if literal =~ /(?:\\)*\\\s*$/
          literal.rstrip!
          literal.chop!
          @trimming = true
        end
        return if @trimming && literal.empty?

        if @trimming
          @multilines << unescape(literal)
        else
          @multilines.concat([unescape(literal), "\n"])
        end
      end
    end
  end

  def build_multiline_string
    string_value = TOMLString.new(@multilines.join)
    lexeme = scanner.string[(@scan_pos - 3)..scanner.pos - 1]
    Rley::Lexical::Literal.new(string_value, lexeme, 'STRING', @string_start)
  end

  def unterminated(_line, _col)
    raise ScanError, "#{error_prefix}: Unterminated string."
  end

  def unescape(aString)
    aString.gsub(PATT_STRING_ESCAPE) do |match|
      match.slice!(0)
      case match[0]
      when ?u
        if match.length < 5
          raise ScanError, "#{error_prefix}: escape sequence \\#{match} must have exactly 4 hexdigits."
        end

        [match[1..-1].hex].pack('U') # Ugly: conversion from codepoint to character
      when ?U
        if match.length < 9
          raise ScanError, "#{error_prefix}: escape sequence \\#{match} must have exactly 8 hexdigits."
        end

        [match[1..-1].hex].pack('U') # Ugly: conversion from codepoint to character
      else
        ch = @@escape_chars[match[0]]
        if ch.nil?
          raise ScanError, "#{error_prefix}: Reserved escape code \\#{match}."
        end

        ch
      end
    end
  end

  def update_keyval_state(aToken)
    case aToken.terminal
    when 'EQUAL'
      equal_scanned
    when 'LBRACKET'
      lbracket_scanned
    when 'RBRACKET'
      rbracket_scanned
    when 'LACCOLADE'
      laccolade_scanned
    when 'RACCOLADE'
      raccolade_scanned
    when 'COMMA', 'UNQUOTED-KEY'
      # Do nothing
    else
      literal_scanned
    end
  end

  # Event: a data literal detected.
  def literal_scanned
    @keyval_stack[-1] = 0 if keyval_stack[-1] == 1
  end

  # Event: an equal sign '=' detected.
  # This forces a transition from :default state to :expecting_value state
  def equal_scanned
    @keyval_stack[-1] = 1
  end

  # Event: an opening square bracket '[' detected.
  def lbracket_scanned
    @keyval_stack[-1] += 1 if state == :expecting_value
  end

  # Event: a closing square bracket ']' detected.
  def rbracket_scanned
    return unless state == :expecting_value

    if @keyval_stack.last == 2
      keyval_stack[-1] = 0
    else
      keyval_stack[-1] -= 1
    end
  end

  # Event: an opening curly accolade '{' detected.
  def laccolade_scanned
    @keyval_stack.push(0)
  end

  # Event: a closing curly accolade '}' detected.
  def raccolade_scanned
    @keyval_stack.pop
    if @keyval_stack.last == 2
      keyval_stack[-1] = 0
    else
      keyval_stack[-1] -= 1
    end
  end

  # Event: next line detected.
  def next_line_scanned
    @lineno += 1
    @line_start = scanner.pos
  end

  def error_prefix
    "Error [#{@string_start.line}:#{@string_start.column}]:"
  end
end # class
# End of file
