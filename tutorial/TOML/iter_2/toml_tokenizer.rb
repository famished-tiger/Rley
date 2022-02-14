# frozen_string_literal: true

require 'strscan'
require 'rley'
require_relative 'toml_datatype'
require_relative 'toml_key'

# A tokenizer for a very limited subset of TOML.
# Responsibilities:
#   - read characters from input string ...
#   - and transform them into a sequence of token objects.
class TOMLTokenizer
  PATT_BOOLEAN = /true|false/.freeze
  PATT_CHAR_SINGLE = /[,=\[\]]/.freeze # Single delimiter or separator character
  PATT_COMMENT = /#[^\r\n]*/.freeze
  PATT_INT_DEC = /[-+]?(?:0|(?:[1-9](?:(?:_\d)|\d)*))(?!\.)/.freeze
  PATT_INT_HEX = /0x[0-9A-Fa-f](?:(?:_[0-9A-Fa-f])|[0-9A-Fa-f])*/.freeze
  PATT_INT_OCT = /0o[0-7](?:(?:_[0-7])|[0-7])*/.freeze
  PATT_INT_BIN = /0b[01](?:(?:_[01])|[01])*/.freeze
  PATT_FLOAT = /[-+]? # Optional sign
    (?:0|(?:[1-9](?:(?:_\d)|\d)*)) # Integer part
    (?:
      ((?: \. (?:[0-9](?:(?:_\d)|\d)*)) (?:[eE][-+]?\d+)?) # fractional part with optional exponent part
      |  (?:[eE][-+]?\d+))/x.freeze # or exponent part
  PATT_FLOAT_SPECIAL = /[-+]?(?:inf|nan)/.freeze
  PATT_NEWLINE = /(?:\r\n)|\r|\n/.freeze
  PATT_MULTI_LINE_STRING_DELIM = /(?:''')|(?:""")/.freeze
  PATT_SINGLE_LINE_STRING_DELIM = /'|"/.freeze
  PATT_STRING_END_LITERAL = /(?:[^']|(?:'(?!''))|(?:''(?!')))*?(?:'''|$)/.freeze
  PATT_STRING_END_ML_BASIC = /(?:[^"\\]
    | (?:"(?!""))
    | (?:""[^"\n\r])
    | (?:\\+"?[^"\n\r])
    | (?:\\(?=\n|\r))
    | (?:(\\\\)+\\"""))*?
    (?:"""|$)/x.freeze
  PATT_UNQUOTED_KEY = /[A-Za-z0-9\-_]+/.freeze
  PATT_WHITESPACE = /[ \t\f]+/.freeze
  # @return [StringScanner] Low-level input scanner
  attr_reader(:scanner)

  # Key track of whether the scanner expects a key or a value
  # This is necessary since the lexeme 1234 can be a bare key or an integer
  # @return [Array<Integer>]
  attr_accessor(:keyval_stack)

  # @return [Integer] The current line number
  attr_reader(:lineno)

  # @return [Integer] Position of last start of line in the input string
  attr_reader(:line_start)

  # Mapping special character tokens to symbolic names
  # @return [{Char => String}]
  Lexeme2name = {
    ',' => 'COMMA',
    '=' => 'EQUAL',
    '[' => 'LBRACKET',
    ']' => 'RBRACKET'
  }.freeze

  # Constructor. Initialize a tokenizer for TOML input.
  # @param source [String] TOML text to tokenize.
  def initialize(source = nil)
    reset
    input = source || ''
    @scanner = StringScanner.new(input)
  end

  # Reset the tokenizer and make the given text, the current input.
  # @param source [String] TOML text to tokenize.
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

  def _next_token
    token = nil

    # Loop until end of input reached or token found
    until token || scanner.eos?
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
          if (lexeme = scanner.scan(PATT_CHAR_SINGLE))
            verbatim_scanned(lexeme)
          elsif (lexeme = scanner.scan(PATT_UNQUOTED_KEY))
            literal_scanned('UNQUOTED-KEY', lexeme, UnquotedKey)
          end

        when :expecting_value
          if (lexeme = scanner.scan(PATT_MULTI_LINE_STRING_DELIM))
            # Start of multi-line string detected...
            string_token = begin_ml_string_token(lexeme)
            next if state == :multiline

            string_token
          elsif (lexeme = scanner.scan(PATT_SINGLE_LINE_STRING_DELIM))
            # Start of single line string detected...
            string_token = single_line_string_token(lexeme)
            update_keyval_state(string_token)
            string_token
          elsif (lexeme = scanner.scan(PATT_CHAR_SINGLE))
            verbatim_scanned(lexeme)
          elsif (lexeme = scanner.scan(PATT_BOOLEAN))
            literal_scanned('BOOLEAN', lexeme, TOMLBoolean)
          elsif (lexeme = scanner.scan(PATT_FLOAT))
            literal_scanned('FLOAT', lexeme, TOMLFloat)
          elsif (lexeme = scanner.scan(PATT_INT_HEX))
            literal_scanned('INTEGER', lexeme, TOMLInteger, :hex)
          elsif (lexeme = scanner.scan(PATT_INT_OCT))
            literal_scanned('INTEGER', lexeme, TOMLInteger, :oct)
          elsif (lexeme = scanner.scan(PATT_INT_BIN))
            literal_scanned('INTEGER', lexeme, TOMLInteger, :bin)
          elsif (lexeme = scanner.scan(PATT_INT_DEC))
            literal_scanned('INTEGER', lexeme, TOMLInteger)
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

          multiline_string_scanned
      end # case state
    end # until

    unterminated(@string_start.line, @string_start.column) if state == :multiline
    token
  end

  # Is the tokenizer expecting a data value?
  # ToS keyval_stack == 0 => false (:default state)
  # ToS keyval_stack > 0 => true (:expecting_value state)
  def expecting_value?
    @keyval_stack.last.positive?
  end

  def verbatim_scanned(aLexeme)
    symbol_name = Lexeme2name[aLexeme]
    begin
      lex_length = aLexeme ? aLexeme.size : 0
      col = scanner.pos - lex_length - @line_start + 1
      pos = Rley::Lexical::Position.new(@lineno, col)
      token = Rley::Lexical::Token.new(aLexeme.dup, symbol_name, pos)
    rescue StandardError => e
      puts "Failing with '#{symbol_name}' and '#{aLexeme}'"
      raise e
    end

    update_keyval_state(token)
    token
  end

  def literal_scanned(aSymbolName, aLexeme, aClass, aFormat = nil)
    value = aClass.new(aLexeme, aFormat)
    lex_length = aLexeme ? aLexeme.size : 0
    col = scanner.pos - lex_length - @line_start + 1
    build_literal(aSymbolName, value, aLexeme, col)
  end

  def build_special_float(aLexeme)
    lex_length = aLexeme ? aLexeme.size : 0
    col = scanner.pos - lex_length - @line_start + 1
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
    build_literal('FLOAT', value, aLexeme, col)
  end

  def build_literal(aSymbolName, aValue, aLexeme, aPosition)
    pos = if aPosition.kind_of?(Integer)
      col = aPosition
      Rley::Lexical::Position.new(@lineno, col)
    else
      aPosition
    end
    literal = Rley::Lexical::Literal.new(aValue, aLexeme.dup, aSymbolName, pos)
    update_keyval_state(literal)
    literal
  end

  def single_line_string_token(delimiter)
    @scan_pos = scanner.pos
    line = @lineno
    column_start = @scan_pos - @line_start
    @string_start = Rley::Lexical::Position.new(line, column_start)
    remainder_pattern = delimiter == "'" ? /[^']*'/ : /(?:[^"]|(?:(?<=\\)"))*"/

    literal = scanner.scan(remainder_pattern)
    unterminated(line, column_start) unless literal
    # raw_value = delimiter == "'" ? literal[0..-2] : unescape(literal[0..-2])
    # string_value = TOMLString.new(raw_value)
    format = delimiter == "'" ? :literal : :basic
    string_value = TOMLString.new(literal[0..-2], format)
    lexeme = scanner.string[(@scan_pos - 1)..scanner.pos - 1]
    Rley::Lexical::Literal.new(string_value, lexeme, 'STRING', @string_start)
  end

  # precondition: current position at leading delimiter
  def begin_ml_string_token(delimiter)
    @scan_pos = scanner.pos
    line = @lineno
    column_start = @scan_pos - @line_start
    @string_start = Rley::Lexical::Position.new(line, column_start)

    case delimiter
    when "'''"
      literal = scanner.scan(PATT_STRING_END_LITERAL)
      unterminated(line, column_start) unless literal
      if literal =~ /'''$/
        # ... single-line string
        build_single_line(literal[0..-4], :literal)
      else
        # ... multi-line literal string
        @state = :multiline
        @string_delimiter = delimiter
        @multilines = literal.empty? ? [] : [literal, "\n"]
      end
    when '"""'
      literal = scanner.scan(PATT_STRING_END_ML_BASIC)
      unterminated(line, column_start) unless literal
      if literal.slice!(/"""$/)
        # ... single-line string
        # build_single_line(unescape(literal), :basic)
        build_single_line(literal, :basic)
      else
        # ... multi-line basic string
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
          @multilines = literal.empty? ? [] : [literal]
          @multilines << "\n" unless @trimming
        end
      end
    end
  end

  def build_single_line(aText, format)
    string_value = TOMLString.new(aText, format)
    lexeme = scanner.string[(@scan_pos - 3)..scanner.pos - 1]
    build_literal('STRING', string_value, lexeme, @string_start)
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
        @multilines << literal unless @trimming && literal.empty?
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
          @multilines << literal
        else
          @multilines.concat([literal, "\n"])
        end
      end
    end
  end

  def multiline_string_scanned
    lexeme = scanner.string[(@scan_pos - 3)..scanner.pos - 1]
    format = (lexeme[0..2] == "'''") ? :literal : :basic
    string_value = TOMLString.new(@multilines.join, format)
    build_literal('STRING', string_value, lexeme, @string_start)
  end

  def unterminated(_line, _col)
    raise ScanError, "#{error_prefix}: Unterminated string."
  end

  def update_keyval_state(aToken)
    case aToken.terminal
    when 'EQUAL'
      equal_found
    when 'LBRACKET'
      lbracket_found
    when 'RBRACKET'
      rbracket_found
    when 'COMMA', 'UNQUOTED-KEY'
      # Do nothing
    else
      literal_found
    end
  end

  # Event: a data literal detected.
  def literal_found
    @keyval_stack[-1] = 0 if keyval_stack[-1] == 1
  end

  # Event: an equal sign '=' detected.
  # This forces a transition from :default state to :expecting_value state
  def equal_found
    @keyval_stack[-1] = 1
  end

  # Event: an opening square bracket '[' detected.
  def lbracket_found
    @keyval_stack[-1] += 1 if state == :expecting_value
  end

  # Event: a closing square bracket ']' detected.
  def rbracket_found
    return unless state == :expecting_value

    decr_keyval_top
  end

  # Event: next line detected.
  def next_line_scanned
    @lineno += 1
    @line_start = scanner.pos
  end

  def decr_keyval_top
    if @keyval_stack.last == 2
      keyval_stack[-1] = 0
    else
      keyval_stack[-1] -= 1
    end
  end

  def error_prefix
    "Error [#{@string_start.line}:#{@string_start.column}]:"
  end
end # class
# End of file
