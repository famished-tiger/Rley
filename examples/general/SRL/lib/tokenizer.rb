# File: srl_tokenizer.rb
# Tokenizer for SRL (Simple Regex Language)
require 'strscan'
require 'rley' # Load the gem

module SRL
  # The tokenizer should recognize:
  # Keywords: as, capture, letter
  # Integer literals including single digit
  # String literals (quote delimited)
  # Single character literal
  # Delimiters: parentheses '(' and ')'
  # Separators: comma (optional)
  class Tokenizer
    attr_reader(:scanner)
    attr_reader(:lineno)
    attr_reader(:line_start)
    attr_reader(:name2symbol)

    @@lexeme2name = {
      '(' => 'LPAREN',
      ')' => 'RPAREN',
      ',' => 'COMMA'
    }.freeze

    # Here are all the SRL keywords (in uppercase)
    @@keywords = %w[
      ALL
      ALREADY
      AND
      ANY
      ANYTHING
      AS
      AT
      BACKSLASH
      BEGIN
      BETWEEN
      BY
      CAPTURE
      CASE
      CHARACTER
      DIGIT
      END
      EXACTLY
      FOLLOWED
      FROM
      HAD
      IF
      INSENSITIVE
      LAZY
      LEAST
      LETTER
      LINE
      LITERALLY
      MORE
      MULTI
      MUST
      NEVER
      NEW
      NO
      NOT
      NUMBER
      OF
      ONCE
      ONE
      OPTIONAL
      OR
      STARTS
      TAB
      TIMES
      TO
      TWICE
      UNTIL
      UPPERCASE
      WHITESPACE
      WITH
    ].map { |x| [x, x] } .to_h

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
      skip_whitespaces
      curr_ch = scanner.peek(1)
      return nil if curr_ch.nil? || curr_ch.empty?

      token = nil

      if '(),'.include? curr_ch
        # Delimiters, separators => single character token
        token = build_token(@@lexeme2name[curr_ch], scanner.getch)
      elsif (lexeme = scanner.scan(/[0-9]{2,}/))
        token = build_token('INTEGER', lexeme) # An integer has two or more digits
      elsif (lexeme = scanner.scan(/[0-9]/))
        token = build_token('DIGIT_LIT', lexeme)
      elsif (lexeme = scanner.scan(/[a-zA-Z]{2,}/))
        token = build_token(@@keywords[lexeme.upcase], lexeme)
        # TODO: handle case unknown identifier
      elsif (lexeme = scanner.scan(/[a-zA-Z]((?=\s)|$)/))
        token = build_token('LETTER_LIT', lexeme)
      elsif (lexeme = scanner.scan(/"([^"]|\\")*"/)) # Double quotes literal?
        unquoted = lexeme.gsub(/(^")|("$)/, '')
        token = build_token('STRING_LIT', unquoted)
      elsif (lexeme = scanner.scan(/'([^']|\\')*'/)) # Single quotes literal?
        unquoted = lexeme.gsub(/(^')|('$)/, '')
        token = build_token('STRING_LIT', unquoted)
      else # Unknown token
        erroneous = curr_ch.nil? ? '' : curr_ch
        sequel = scanner.scan(/.{1,20}/)
        erroneous += sequel unless sequel.nil?
        raise ScanError.new("Unknown token #{erroneous}")
      end

      return token
    end

    def build_token(aSymbolName, aLexeme)
      token_type = name2symbol[aSymbolName]
      begin
        token = Rley::Lexical::Token.new(aLexeme, token_type)
      rescue Exception => ex
        puts "Failing with '#{aSymbolName}' and '#{aLexeme}'"
        raise ex
      end

      return token
    end

    def skip_whitespaces()
      scanner.scan(/[ \t\f\n\r]+/)
    end
  end # class
end # module
