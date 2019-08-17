# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module AmbiguousGrammarHelper
  # Factory method. Creates a grammar builder for a basic ambiguous
  # expression grammar.
  # (based on an example from Fisher and LeBlanc: "Crafting a Compiler")
  def grammar_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('+', 'id')
      rule 'S' => 'E'
      rule 'E' => %w[E + E]
      rule 'E' => 'id'
    end
    builder
  end

  # Basic tokenizing method
  def tokenize(aText, aGrammar)
    tokens = aText.scan(/\S+/).map do |lexeme|
      case lexeme
        when '+'
          terminal = aGrammar.name2symbol[lexeme]
        when /^[_a-zA-Z][_a-zA-Z0-9]*$/
          terminal = aGrammar.name2symbol['id']
        else
          msg = "Unknown input text '#{lexeme}'"
          raise StandardError, msg
      end
      pos = Rley::Lexical::Position.new(3, 4) # dummy pos
      Rley::Lexical::Token.new(lexeme, terminal, pos)
    end

    return tokens
  end
end # module
