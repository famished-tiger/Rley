# frozen_string_literal: true

require 'strscan'

# Load the builder class
require_relative '../../../lib/rley/notation/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module GrammarIntSeqHelper
  # Factory method. Creates a builder for a grammar of sequence
  # of positive integers.
  def grammar_int_seq_builder
    Rley::Notation::GrammarBuilder.new do
      add_terminals('comma', 'digit')
      rule 'S' => 'sequence'
      rule 'S' => ''
      rule 'sequence' => 'sequence comma integer'
      rule 'sequence' => 'integer'
      rule 'integer' => 'digit+'
    end
  end

  # Basic tokenizer for sequence positive integers
  def int_seq_tokenizer(aText)
    scanner = StringScanner.new(aText)
    tokens = []

    loop do
      scanner.skip(/\s+/)
      break if scanner.eos?

      curr_pos = scanner.pos

      if (lexeme = scanner.scan(/,/))
        terminal = 'comma'
      elsif (lexeme = scanner.scan(/\d/))
        terminal = 'digit'
      else
        msg = "Unknown input text '#{scanner.scan(/.*/)}'"
        raise StandardError, msg
      end

      pos = Rley::Lexical::Position.new(1, curr_pos + 1)
      tokens << Rley::Lexical::Token.new(lexeme, terminal, pos)
    end

    return tokens
  end
end # module
# End of file
