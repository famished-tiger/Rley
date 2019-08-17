# frozen_string_literal: true

# File: json_lexer.rb
# Lexer for the JSON data format
require 'rley' # Load the gem
require 'strscan'

# Lexer for JSON.
class JSONLexer
  attr_reader(:scanner)
  attr_reader(:lineno)
  attr_reader(:line_start)

  @@lexeme2name = {
    '{' => 'begin-object',
    '}' => 'end-object',
    '[' => 'begin-array',
    ']' => 'end-array',
    ',' => 'value-separator',
    ':' => 'name-separator'
  }.freeze

  class ScanError < StandardError; end

  def initialize(source)
    @scanner = StringScanner.new(source)
    @lineno = 1
    @line_start = 0
  end

  def tokens()
    tok_sequence = []
    until @scanner.eos?
      token = _next_token
      tok_sequence << token unless token.nil?
    end

    return tok_sequence
  end

  private

  def _next_token()
    token = nil
    skip_whitespaces
    curr_ch = scanner.getch # curr_ch is at start of token or eof reached...

    loop do
      break if curr_ch.nil?

      case curr_ch
        when '{', '}', '[', ']', ',', ':'
          token_type = @@lexeme2name[curr_ch]
          token = build_token(curr_ch, token_type)

        when /[ftn]/ # First letter of keywords
          @scanner.pos = scanner.pos - 1 # Simulate putback
          keyw = scanner.scan(/false|true|null/)
          if keyw.nil?
            invalid_keyw = scanner.scan(/\w+/)
            raise ScanError.new("Invalid keyword: #{invalid_keyw}")
          else
            token = build_token(keyw, keyw)
          end

        # LITERALS
        when '"' # Start string delimiter found
          value = scanner.scan(/([^"\\]|\\.)*/)
          end_delimiter = scanner.getch
          err_msg = 'No closing quotes (") found'
          raise ScanError.new(err_msg) if end_delimiter.nil?

          token = build_token(value, 'string')

        when /[-0-9]/ # Start character of number literal found
          @scanner.pos = scanner.pos - 1 # Simulate putback
          value = scanner.scan(/-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9])?/)
          token = build_token(value, 'number')

        else # Unknown token
          erroneous = curr_ch.nil? ? '' : curr_ch
          sequel = scanner.scan(/.{1,20}/)
          erroneous += sequel unless sequel.nil?
          raise ScanError.new("Unknown token #{erroneous}")
      end # case
      break unless token.nil? && (curr_ch = scanner.getch)
    end

    return token
  end

  def build_token(lexeme, token)
    pos = Rley::Lexical::Position.new(lineno, scanner.pos - line_start)
    Rley::Lexical::Token.new(lexeme, token, pos)
  end

  def skip_whitespaces()
    matched = scanner.scan(/[ \t\f\n\r]+/)
    return if matched.nil?

    newline_count = 0
    matched.scan(/\n\r?|\r/) { |_| newline_count += 1 }
    newline_detected(newline_count)
  end

  def newline_detected(count)
    @lineno += count
    @line_start = scanner.pos
  end
end # class
