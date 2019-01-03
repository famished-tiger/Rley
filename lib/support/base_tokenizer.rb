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
  # Conditional single character:
  #  (e.g. '+' operator, '+' prefix for positive numbers) 
  def _next_token
    skip_whitespaces
    curr_ch = scanner.peek(1)
    return nil if curr_ch.nil? || curr_ch.empty?

    token = recognize_token
    if token.nil? # Unknown token
      curr_ch = scanner.peek(1)
      erroneous = curr_ch.nil? ? '' : scanner.scan(/./)
      sequel = scanner.scan(/.{1,20}/)
      erroneous += sequel unless sequel.nil?
      raise ScanError, "Unknown token #{erroneous} on line #{lineno}"
    end

    return token
  end
  
  def recognize_token
    raise NotImplementedError
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
  
  def convert_to(aLexeme, _symbol_name, _format)
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
      #   cmt_found = true
      #   scanner.skip(/;[^\r\n]*(?:(?:\r\n)|\r|\n)?/)
      #   next_line
      # end
      break unless ws_found || cmt_found
    end

    curr_pos = scanner.pos
    return if curr_pos == pre_pos
  end
  
  def next_line
    @lineno += 1
    @line_start = scanner.pos
  end  
end # class
