# frozen_string_literal: true

require 'strscan'
require 'rley'
require_relative 'toml_datatype'

# A tokenizer for a very limited subset of TOML.
# Responsibilities:
#   - read characters from input string ...
#   - and transform them into a sequence of token objects.
class TOMLTokenizer
  # rubocop: disable Style/RedundantRegexpCharacterClass

  PATT_BOOLEAN = /true|false/.freeze
  PATT_COMMENT = /#[^\r\n]*/.freeze
  PATT_NEWLINE = /(?:\r\n)|\r|\n/.freeze
  PATT_SINGLE_CHAR = /[=]/.freeze # Single delimiter or separator character
  PATT_UNQUOTED_KEY = /[A-Za-z0-9\-_]+/.freeze
  PATT_WHITESPACE = /[ \t\f]+/.freeze
  # rubocop: enable Style/RedundantRegexpCharacterClass

  # @return [StringScanner] Low-level input scanner
  attr_reader(:scanner)

  # @return [Symbol] Current lexical state
  attr_reader(:state)

  # @return [Integer] The current line number
  attr_reader(:lineno)

  # @return [Integer] Position of last start of line in the input string
  attr_reader(:line_start)

  # One or two special character tokens.
  @@lexeme2name = {
    '=' => 'EQUAL'
  }.freeze

  # Constructor. Initialize a tokenizer for TOML input.
  # @param source [String] TOML text to tokenize.
  def initialize(source = nil)
    @scanner = StringScanner.new('')
    @state = :default
    start_with(source) if source
  end

  # Reset the tokenizer and make the given text, the current input.
  # @param source [String] TOML text to tokenize.
  def start_with(source)
    @scanner.string = source
    @state = :default
    @lineno = 1
    @line_start = 0
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

  def _next_token
    token = nil

    # Loop until end of input reached or token found
    until token || scanner.eos?
      nl_found = scanner.skip(PATT_NEWLINE)
      if nl_found
        next_line
        next
      end

      token = case state
        when :default
          next if scanner.skip(PATT_WHITESPACE) # Skip whitespaces

          curr_ch = scanner.peek(1)

          if curr_ch == '#'
            # Start of comment detected...
            scanner.skip(PATT_COMMENT) # Skip line comment
            next
          elsif curr_ch == '"'
            # Start of string detected...
            build_string_token
          elsif (lexeme = scanner.scan(PATT_SINGLE_CHAR))
            build_token(@@lexeme2name[curr_ch], lexeme)
          elsif (lexeme = scanner.scan(PATT_BOOLEAN))
            build_token('BOOLEAN', lexeme)
          elsif (lexeme = scanner.scan(PATT_UNQUOTED_KEY))
            build_token('UNQUOTED-KEY', lexeme)
          else # Unknown token
            col = scanner.pos - @line_start + 1
            _erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
            raise ScanError, "Error: [line #{lineno}:#{col}]: Unexpected character."
          end
      end # case state
    end # until

    token
  end

  def build_token(aSymbolName, aLexeme)
    begin
      (value, symb) = convert_to(aLexeme, aSymbolName)
      lex_length = aLexeme ? aLexeme.size : 0
      col = scanner.pos - lex_length - @line_start + 1
      pos = Rley::Lexical::Position.new(@lineno, col)
      if value
        token = Rley::Lexical::Literal.new(value, aLexeme.dup, symb, pos)
      else
        token = Rley::Lexical::Token.new(aLexeme.dup, symb, pos)
      end
    rescue StandardError => e
      puts "Failing with '#{aSymbolName}' and '#{aLexeme}'"
      raise e
    end

    token
  end

  def convert_to(aLexeme, aSymbolName)
    symb = aSymbolName
    case aSymbolName
      when 'BOOLEAN'
        value = TOMLBoolean.new(aLexeme == 'true')
      when 'UNQUOTED-KEY'
        value = UnquotedKey.new(aLexeme)
      else
        value = nil
    end

    return [value, symb]
  end

  # precondition: current position at leading quote
  def build_string_token
    @state = :in_string
    scan_pos = scanner.pos
    line = @lineno
    column_start = scan_pos - @line_start

    literal = scanner.scan(/"[^"]*"/)
    unless literal
      pos_start = "line #{line}:#{column_start}"
      raise ScanError, "Error: [#{pos_start}]: Unterminated string."
    end

    @state = :default
    pos = Rley::Lexical::Position.new(line, column_start)
    basic_string = TOMLString.new(literal[1..-2])
    lexeme = scanner.string[scan_pos..scanner.pos - 1]
    Rley::Lexical::Literal.new(basic_string, lexeme, 'STRING', pos)
  end

  def next_line
    @lineno += 1
    @line_start = scanner.pos
  end
end # class
# End of file
