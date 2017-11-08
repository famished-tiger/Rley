# File: json_lexer.rb
# Lexer for the JSON data format
require 'rley' # Load the gem
require 'strscan'

# Lexer for JSON.
class JSONLexer
  attr_reader(:scanner)
  attr_reader(:lineno)
  attr_reader(:line_start)
  attr_reader(:name2symbol)

  @@lexeme2name = {
    '{' => 'begin-object',
    '}' => 'end-object',
    '[' => 'begin-array',
    ']' => 'end-array',
    ',' => 'value-separator',
    ':' => 'name-separator'
  }.freeze

  class ScanError < StandardError; end

  def initialize(source, aGrammar)
    @scanner = StringScanner.new(source)
    @name2symbol = aGrammar.name2symbol
    @lineno = 1
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
          type_name = @@lexeme2name[curr_ch]
          token_type = name2symbol[type_name]
          token = Rley::Lexical::Token.new(curr_ch, token_type)

        when /[ftn]/ # First letter of keywords
          @scanner.pos = scanner.pos - 1 # Simulate putback
          keyw = scanner.scan(/false|true|null/)
          if keyw.nil?
            invalid_keyw = scanner.scan(/\w+/)
            raise ScanError.new("Invalid keyword: #{invalid_keyw}")
          else
            token_type = name2symbol[keyw]
            token = Rley::Lexical::Token.new(keyw, token_type)
          end

        # LITERALS
        when '"' # Start string delimiter found
          value = scanner.scan(/([^"\\]|\\.)*/)
          end_delimiter = scanner.getch
          err_msg = 'No closing quotes (") found'
          raise ScanError.new(err_msg) if end_delimiter.nil?
          token_type = name2symbol['string']
          token = Rley::Lexical::Token.new(value, token_type)

        when /[-0-9]/ # Start character of number literal found
          @scanner.pos = scanner.pos - 1 # Simulate putback
          value = scanner.scan(/-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9])?/)
          token_type = name2symbol['number']
          token = Rley::Lexical::Token.new(value, token_type)

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
