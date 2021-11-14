# frozen_string_literal: true

require 'strscan'
require 'rley'
require_relative 'toml_datatype'

# A tokenizer for a very limited subset of TOML.
# Responsibilities:
#   - read characters from input string ...
#   - and transform them into a sequence of token objects.
class TOMLTokenizer
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

  # Constructor. Initialize a tokenizer for Lox input.
  # @param source [String] Lox text to tokenize.
  def initialize(source = nil)
    @scanner = StringScanner.new('')
    @state = :default
    start_with(source) if source
  end

  # Reset the tokenizer and make the given text, the current input.
  # @param source [String] Lox text to tokenize.
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

    until scanner.eos? || token
      nl_found = scanner.skip(/(?:\r\n)|\r|\n/)
      if nl_found
        next_line
        next
      end

      token = case state
        when :default
          next if scanner.skip(/[ \t\f]+/) # Skip whitespaces

          curr_ch = scanner.peek(1)

          if curr_ch == '#'
            scanner.skip(/#[^\r\n]*/) # Skip line comment
            next

          elsif '='.include? curr_ch
            # Single delimiter or separator character
            build_token(@@lexeme2name[curr_ch], scanner.getch)
          elsif (lexeme = scanner.scan(/false|true/))
            build_token('BOOLEAN', lexeme)
          elsif (lexeme = scanner.scan(/[a-zA-Z0-9\-_]+/))
            build_token('UNQUOTED-KEY', lexeme)
          elsif scanner.scan(/"/) # Start of string detected...
            build_string_token
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

    literal = scanner.scan(/[^"]*"/)
    unless literal
      pos_start = "line #{line}:#{column_start}"
      raise ScanError, "Error: [#{pos_start}]: Unterminated string."
    end

    @state = :default
    pos = Rley::Lexical::Position.new(line, column_start)
    basic_string = TOMLString.new(literal.chop)
    lexeme = scanner.string[scan_pos - 1..scanner.pos - 1]
    Rley::Lexical::Literal.new(basic_string, lexeme, 'BASIC-STRING', pos)
  end

  def next_line
    @lineno += 1
    @line_start = scanner.pos
  end
end # class
# End of file
