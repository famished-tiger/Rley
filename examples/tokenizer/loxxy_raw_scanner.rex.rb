# frozen_string_literal: true

# encoding: UTF-8
#--
# This file is automatically generated. Do not modify it.
# Generated by: oedipus_lex version 2.5.3.
# Source: loxxy_raw_scanner.rex
#++

# rubocop: disable Style/MutableConstant
# rubocop: disable Layout/SpaceBeforeSemicolon
# rubocop: disable Style/Alias
# rubocop: disable Style/AndOr
# rubocop: disable Style/MultilineIfModifier
# rubocop: disable Style/StringLiterals
# rubocop: disable Style/MethodDefParentheses
# rubocop: disable Security/Open
# rubocop: disable Style/TrailingCommaInArrayLiteral
# rubocop: disable Layout/EmptyLinesAroundMethodBody
# rubocop: disable Style/WhileUntilDo
# rubocop: disable Style/MultilineWhenThen
# rubocop: disable Layout/ExtraSpacing
# rubocop: disable Layout/SpaceInsideRangeLiteral
# rubocop: disable Style/CaseEquality
# rubocop: disable Style/EmptyCaseCondition
# rubocop: disable Style/SymbolArray
# rubocop: disable Lint/DuplicateBranch
# rubocop: disable Layout/EmptyLineBetweenDefs
# rubocop: disable Layout/IndentationConsistency


##
# The generated lexer LoxxyRawScanner

class LoxxyRawScanner
  require 'strscan'

  # :stopdoc:
  DIGIT = /\d/
  ALPHA = /[a-zA-Z_]/
  # :startdoc:
  # :stopdoc:
  class LexerError < StandardError ; end
  class ScanError < LexerError ; end
  # :startdoc:

  ##
  # The current line number.

  attr_accessor :lineno
  ##
  # The file name / path

  attr_accessor :filename

  ##
  # The StringScanner for this lexer.

  attr_accessor :ss

  ##
  # The current lexical state.

  attr_accessor :state

  alias :match :ss

  ##
  # The match groups for the current scan.

  def matches
    m = (1..9).map { |i| ss[i] }
    m.pop until m[-1] or m.empty?
    m
  end

  ##
  # Yields on the current action.

  def action
    yield
  end

  ##
  # The previous position. Only available if the :column option is on.

  attr_accessor :old_pos

  ##
  # The position of the start of the current line. Only available if the
  # :column option is on.

  attr_accessor :start_of_current_line_pos

  ##
  # The current column, starting at 0. Only available if the
  # :column option is on.
  def column
    old_pos - start_of_current_line_pos
  end


  ##
  # The current scanner class. Must be overridden in subclasses.

  def scanner_class
    StringScanner
  end unless instance_methods(false).map(&:to_s).include?("scanner_class")

  ##
  # Parse the given string.

  def parse str
    self.ss     = scanner_class.new str
    self.lineno = 1
    self.start_of_current_line_pos = 0
    self.state  ||= nil

    do_parse
  end

  ##
  # Read in and parse the file at +path+.

  def parse_file path
    self.filename = path
    open path do |f|
      parse f.read
    end
  end

  ##
  # The current location in the parse.

  def location
    [
      (filename || "<input>"),
      lineno,
      column,
    ].compact.join(":")
  end

  ##
  # Lex the next token.

  def next_token

    token = nil

    until ss.eos? or token do
      if ss.peek(1) == "\n"
        self.lineno += 1
        # line starts 1 position after the newline
        self.start_of_current_line_pos = ss.pos + 1
      end
      self.old_pos = ss.pos
      token =
        case state
        when nil then
          case
          when ss.skip(/[ \t]+/) then
            # do nothing
          when ss.skip(/\/\/[^\r\n]*/) then
            # do nothing
          when text = ss.scan(/\r|\n/) then
            newline text
          when text = ss.scan(/[!=<>]=?/) then
            action { [:SPECIAL, text] }
          when text = ss.scan(/[(){},;.\-+\/*]/) then
            action { [:SPECIAL, text] }
          when text = ss.scan(/#{DIGIT}+(\.#{DIGIT}+)?/) then
            action { [:NUMBER, text] }
          when text = ss.scan(/nil/) then
            action { [:NIL, text] }
          when text = ss.scan(/false/) then
            action { [:FALSE, text] }
          when text = ss.scan(/true/) then
            action { [:TRUE, text] }
          when text = ss.scan(/#{ALPHA}(#{ALPHA}|#{DIGIT})*/) then
            action { [:IDENTIFIER, text] }
          when ss.skip(/""/) then
            action { [:STRING, '""'] }
          when ss.skip(/"/) then
            [:state, :IN_STRING]
          else
            text = ss.string[ss.pos .. -1]
            raise ScanError, "can not match (#{state.inspect}) at #{location}: '#{text}'"
          end
        when :IN_STRING then
          case
          when text = ss.scan(/[^"]+/) then
            action { [:STRING, "\"#{text}\""] }
          when ss.skip(/"/) then
            [:state, nil]
          else
            text = ss.string[ss.pos .. -1]
            raise ScanError, "can not match (#{state.inspect}) at #{location}: '#{text}'"
          end
        else
          raise ScanError, "undefined state at #{location}: '#{state}'"
        end # token = case state

      next unless token # allow functions to trigger redo w/ nil
    end # while

    raise LexerError, "bad lexical result at #{location}: #{token.inspect}" unless
      token.nil? || (Array === token && token.size >= 2)

    # auto-switch state
    self.state = token.last if token && token.first == :state

    token
  end # def next_token
    def do_parse
      tokens = []
      while (tok = next_token) do
        (type, lexeme) = tok
        if type == :state
          self.state = lexeme
          next
        else
          tokens << [type, lexeme, lineno, column]
        end
      end
      tokens
    end
    def newline(txt)
      if txt == '\r'
        ss.skip(/\n/) # CR LF sequence
        self.lineno += 1
        self.start_of_current_line_pos = ss.pos + 1
      end
      nil
    end
end # class

  # rubocop: enable Style/MutableConstant
  # rubocop: enable Layout/SpaceBeforeSemicolon
  # rubocop: enable Style/Alias
  # rubocop: enable Style/AndOr
  # rubocop: enable Style/MultilineIfModifier
  # rubocop: enable Style/StringLiterals
  # rubocop: enable Style/MethodDefParentheses
  # rubocop: enable Security/Open
  # rubocop: enable Style/TrailingCommaInArrayLiteral
  # rubocop: enable Layout/EmptyLinesAroundMethodBody
  # rubocop: enable Style/WhileUntilDo
  # rubocop: enable Style/MultilineWhenThen
  # rubocop: enable Layout/ExtraSpacing
  # rubocop: enable Layout/SpaceInsideRangeLiteral
  # rubocop: enable Style/CaseEquality
  # rubocop: enable Style/EmptyCaseCondition
  # rubocop: enable Style/SymbolArray
  # rubocop: enable Lint/DuplicateBranch
  # rubocop: enable Layout/EmptyLineBetweenDefs
  # rubocop: enable Layout/IndentationConsistency
