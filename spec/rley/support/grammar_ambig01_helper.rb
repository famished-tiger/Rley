# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module GrammarAmbig01Helper
  ########################################
  # Factory method. Define a grammar for a very simple language
  # Grammar 3: An ambiguous arithmetic expression language
  # (based on example in article on Earley's algorithm in Wikipedia)
  def grammar_ambig01_builder
    Rley::Syntax::GrammarBuilder.new do
      add_terminals('integer', '+', '*')
      rule 'P' => 'S'
      rule 'S' => 'S + S'
      rule 'S' => 'S * S'
      rule 'S' => 'L'
      rule 'L' => 'integer'
    end
  end

  # Highly simplified tokenizer implementation.
  def tokenizer_ambig01(aText)
    scanner = StringScanner.new(aText)
    tokens = []

    loop do
      scanner.skip(/\s+/)
      curr_pos = scanner.pos
      lexeme = scanner.scan(/\S+/)
      break unless lexeme

      case lexeme
        when '+', '*'
          terminal = lexeme
        when /^[-+]?\d+$/
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
