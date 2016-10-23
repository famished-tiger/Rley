# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/token'


module AmbiguousGrammarHelper
  # Factory method. Creates a grammar builder for a basic ambiguous
  # expression grammar.
  # (based on an example from Fisher and LeBlanc: "Crafting a Compiler")
  def grammar_builder()
    builder = Rley::Syntax::GrammarBuilder.new
    builder.add_terminals('+', 'id')
    builder.add_production('S' => 'E')
    builder.add_production('E' => %w(E + E))
    builder.add_production('E' => 'id')
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
          fail StandardError, msg
      end
      Rley::Parser::Token.new(lexeme, terminal)
    end

    return tokens
  end
end # module
