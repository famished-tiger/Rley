# frozen_string_literal: true

require 'strscan'

# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module GrammarArrIntHelper
  # Factory method. Creates a grammar builder for a grammar of
  # array of integers.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_arr_int_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('[', ']', ',', 'integer')
      rule 'P' => 'arr'
      rule 'arr' => %w([ sequence ])
      rule 'sequence' => 'list'
      rule 'sequence' => []
      rule 'list' => %w[list , integer] # Left-recursive rule
      rule 'list' => 'integer'
    end
    builder
  end

  # Basic tokenizer for array of integers
  def arr_int_tokenizer(aText)
    scanner = StringScanner.new(aText)
    tokens = []

    loop do
      scanner.skip(/\s+/)
      curr_ch = scanner.peek(1)
      break if curr_ch.nil? || curr_ch.empty?

      curr_pos = scanner.pos

      if (lexeme = scanner.scan(/[\[\],]/))
        terminal = lexeme
      elsif (lexeme = scanner.scan(/[-+]?\d+/))
        terminal = 'integer'
      else
        msg = "Unknown input text '#{lexeme}'"
        raise StandardError, msg
      end

      pos = Rley::Lexical::Position.new(1, curr_pos + 1)
      tokens << Rley::Lexical::Token.new(lexeme, terminal, pos)
    end

    return tokens
  end
end # module
# End of file
