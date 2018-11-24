require 'strscan'
require_relative '../rley/lexical/token'

class BaseTokenizer
  attr_reader(:scanner)
  attr_reader(:lineno)
  attr_reader(:line_start)
  
  class ScanError < StandardError; end

  # Constructor. Initialize a tokenizer for Skeem.
  # @param source [String] Skeem text to tokenize.
  def initialize(source)
    @scanner = StringScanner.new('')
    restart(source)
  end

  # @param source [String] Skeem text to tokenize.
  def restart(source)
    @scanner.string = source
    @lineno = 1
    @line_start = 0
  end

  # @return [Array<SkmToken>] | Returns a sequence of tokens
  def tokens
    tok_sequence = []
    until @scanner.eos?
      token = _next_token
      tok_sequence << token unless token.nil?
    end

    return tok_sequence
  end
  
  protected
  
  # Patterns:
  # Unambiguous single character
  # Conditional single character (e.g. '+' operator, '+' prefix for positive numbers) 
  def _next_token
    skip_whitespaces
    curr_ch = scanner.peek(1)
    return nil if curr_ch.nil? || curr_ch.empty?

    token = recognize_token()
    if token.nil? # Unknown token
      curr_ch = scanner.peek(1)
      erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
      sequel = scanner.scan(/.{1,20}/)
      erroneous += sequel unless sequel.nil?
      raise ScanError, "Unknown token #{erroneous} on line #{lineno}"
    end

    return token
  end
  
  def recognize_token()
=begin
    if "()'`".include? curr_ch # Single characters
      # Delimiters, separators => single character token
      token = build_token(@@lexeme2name[curr_ch], scanner.getch)
    elsif (lexeme = scanner.scan(/(?:\.)(?=\s)/)) # Single char occurring alone
      token = build_token('PERIOD', lexeme)
    elsif (lexeme = scanner.scan(/,@?/))
      token = build_token(@@lexeme2name[lexeme], lexeme)
    elsif (lexeme = scanner.scan(/#(?:(?:true)|(?:false)|(?:u8)|[\\\(tfeiodx]|(?:\d+[=#]))/))
      token = cardinal_token(lexeme)        
    elsif (lexeme = scanner.scan(/[+-]?[0-9]+(?=\s|[|()";]|$)/))
      token = build_token('INTEGER', lexeme) # Decimal radix
    elsif (lexeme = scanner.scan(/[+-]?[0-9]+(?:\.[0-9]+)?(?:(?:e|E)[+-]?[0-9]+)?/))
      # Order dependency: must be tested after INTEGER case
      token = build_token('REAL', lexeme)
    elsif (lexeme = scanner.scan(/"(?:\\"|[^"])*"/)) # Double quotes literal?
      token = build_token('STRING_LIT', lexeme)
    elsif (lexeme = scanner.scan(/[a-zA-Z!$%&*\/:<=>?@^_~][a-zA-Z0-9!$%&*+-.\/:<=>?@^_~+-]*/))
      keyw = @@keywords[lexeme.upcase]
      tok_type = keyw ? keyw : 'IDENTIFIER'
      token = build_token(tok_type, lexeme)
    elsif (lexeme = scanner.scan(/\|(?:[^|])*\|/)) # Vertical bar delimited
      token = build_token('IDENTIFIER', lexeme)
    elsif (lexeme = scanner.scan(/([\+\-])((?=\s|[|()";])|$)/))
      #  # R7RS peculiar identifiers case 1: isolated plus and minus as identifiers
      token = build_token('IDENTIFIER', lexeme)
    elsif (lexeme = scanner.scan(/[+-][a-zA-Z!$%&*\/:<=>?@^_~+-@][a-zA-Z0-9!$%&*+-.\/:<=>?@^_~+-]*/))
      # R7RS peculiar identifiers case 2
      token = build_token('IDENTIFIER', lexeme)
    elsif (lexeme = scanner.scan(/\.[a-zA-Z!$%&*\/:<=>?@^_~+-@.][a-zA-Z0-9!$%&*+-.\/:<=>?@^_~+-]*/))
      # R7RS peculiar identifiers case 4
      token = build_token('IDENTIFIER', lexeme)
=end  
  end
  
  def build_token(aSymbolName, aLexeme, aFormat = :default)
    begin
      value = convert_to(aLexeme, aSymbolName, aFormat)
      col = scanner.pos - aLexeme.size - @line_start + 1
      pos = Rley::Lexical::Position.new(@lineno, col)
      token = Rley::Lexical::Token.new(value, aSymbolName, pos)
    rescue StandardError => exc
      puts "Failing with '#{aSymbolName}' and '#{aLexeme}'"
      raise exc
    end

    return token
  end
  
  def convert_to(aLexeme, aSymbolName, aFormat)
    return aLexeme
  end
 
  def skip_whitespaces
    pre_pos = scanner.pos

    loop do
      ws_found = false
      cmt_found = false
      found = scanner.skip(/[ \t\f]+/)
      ws_found = true if found
      found = scanner.skip(/(?:\r\n)|\r|\n/)
      if found
        ws_found = true
        next_line
      end
      # next_ch = scanner.peek(1)
      # if next_ch == ';'
        # cmt_found = true
        # scanner.skip(/;[^\r\n]*(?:(?:\r\n)|\r|\n)?/)
        # next_line
      # end
      break unless ws_found or cmt_found
    end

    curr_pos = scanner.pos
    return if curr_pos == pre_pos
  end
  
  def next_line
    @lineno += 1
    @line_start = scanner.pos
  end  
end # class
=begin  
require 'base_tokenizer'

class PB_Tokenizer < BaseTokenizer
  @@lexeme2name = {
    '(' => 'LPAREN',
    ')' => 'RPAREN',
    '+' => 'PLUS',
  }.freeze

  protected
  
  def recognize_token()
    token = nil
    curr_ch = scanner.peek(1)
    
    if '()'.include? curr_ch # Single characters
      # Delimiters, separators => single character token
      token = build_token(@@lexeme2name[curr_ch], scanner.getch)
    elsif (lexeme = scanner.scan(/(?:\+)(?=\s)/)) # Single char occurring alone
      token = build_token(@@lexeme2name[lexeme], lexeme)
     elsif (lexeme = scanner.scan(/[+-]?[0-9]+/))
      token = build_token('INTEGER', lexeme)
    end
  end
end # class

  # Basic tokenizer
  # @return [Array<Rley::Lexical::Token>]
  def tokenize(aText)
    tokenizer = PB_Tokenizer.new(aText)
    tokenizer.token
  end

=end 
=begin  
  # Basic expression tokenizer
  def tokenize(aText)
    tokens = aText.scan(/\S+/).map do |lexeme|
      case lexeme
        when '+', '(', ')'
          terminal = @grammar.name2symbol[lexeme]
        when /^[-+]?\d+$/
          terminal = @grammar.name2symbol['int']
        else
          msg = "Unknown input text '#{lexeme}'"
          raise StandardError, msg
      end
      pos = Rley::Lexical::Position.new(1, 4) # Dummy position
      Rley::Lexical::Token.new(lexeme, terminal, pos)
    end

    return tokens
  end
=end