# frozen_string_literal: true

# File: calc_lexer.rb
# Lexer for a basic arithmetical expression parser
require 'strscan'
require 'rley' # Load the gem


class CalcLexer
  attr_reader(:scanner)
  attr_reader(:lineno)
  attr_reader(:line_start)

  @@lexeme2name = {
    '(' => 'LPAREN',
    ')' => 'RPAREN',
    '+' => 'PLUS',
    '-' => 'MINUS',
    '*' => 'STAR',
    '/' => 'DIVIDE',
    '**' => 'POWER'
  }.freeze

  class ScanError < StandardError; end

  def initialize(source)
    @scanner = StringScanner.new(source)
    @lineno = 1
  end

  def tokens
    tok_sequence = []
    until @scanner.eos?
      token = _next_token
      tok_sequence << token unless token.nil?
    end

    return tok_sequence
  end

  private

  # rubocop: disable Lint/DuplicateBranch
  def _next_token
    skip_whitespaces
    curr_ch = scanner.peek(1)
    return nil if curr_ch.nil?

    token = nil

    if '()+/'.include? curr_ch
      # Single character token
      token = build_token(@@lexeme2name[curr_ch], scanner.getch)

    elsif (lexeme = scanner.scan(/\*\*/))
      token = build_token(@@lexeme2name[lexeme], lexeme)
    elsif (lexeme = scanner.scan(/\*/))
      token = build_token(@@lexeme2name[lexeme], lexeme)
    elsif (lexeme = scanner.scan(/-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9])?/))
      token = build_token('NUMBER', lexeme)
    elsif (lexeme = scanner.scan(/-/))
      token = build_token(@@lexeme2name[curr_ch], lexeme)
    else # Unknown token
      erroneous = curr_ch.nil? ? '' : curr_ch
      sequel = scanner.scan(/.{1,20}/)
      erroneous += sequel unless sequel.nil?
      raise ScanError, "Unknown token #{erroneous}"
    end

    return token
  end
  # rubocop: enable Lint/DuplicateBranch

  def build_token(aSymbolName, aLexeme)
    pos = Rley::Lexical::Position.new(1, scanner.pos)
    return Rley::Lexical::Token.new(aLexeme, aSymbolName, pos)
  end

  def skip_whitespaces
    scanner.scan(/[ \t\f\n\r]+/)
  end
end # class
