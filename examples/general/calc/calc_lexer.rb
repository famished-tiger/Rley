# File: calc_lexer.rb
# Lexer for a basic arithmetical expression parser
require 'strscan'
require 'rley'  # Load the gem


class CalcLexer
  attr_reader(:scanner)
  attr_reader(:lineno)
  attr_reader(:line_start)
  attr_reader(:name2symbol)

  @@lexeme2name = {
    '(' => 'LPAREN',
    ')' => 'RPAREN',
    '+' => 'PLUS',
    '-' => 'MINUS',
    '*' => 'STAR',
    '/' => 'DIVIDE',
  }

  class ScanError < StandardError ; end

public
  def initialize(source, aGrammar)
    @scanner = StringScanner.new(source)
    @name2symbol = aGrammar.name2symbol
    @lineno =  1
  end

  def tokens()
    tok_sequence = []
    until @scanner.eos? do
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

    begin
      break if curr_ch.nil?

      case curr_ch
        when '(', ')', '+', '-', '*', '/'
          type_name = @@lexeme2name[curr_ch]
          token_type = name2symbol[type_name]
          token = Rley::Parser::Token.new(curr_ch, token_type)

        # LITERALS
        when /[-0-9]/ # Start character of number literal found
          @scanner.pos = scanner.pos - 1 # Simulate putback
          value = scanner.scan(/-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9])?/)
          token_type = name2symbol['NUMBER']
          token = Rley::Parser::Token.new(value, token_type)


        else # Unknown token
          erroneous = curr_ch.nil? ? '' : curr_ch
          sequel = scanner.scan(/.{1,20}/)
          erroneous += sequel unless sequel.nil?
          raise ScanError.new("Unknown token #{erroneous}")
      end #case


    end while (token.nil? && curr_ch = scanner.getch())

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
    @line_start = scanner.pos()
  end

end # class