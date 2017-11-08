# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


# Utility class.
class GrammarPBHelper
  # Factory method. Creates a grammar for a basic arithmetic
  # expression based on example found in paper of
  # K. Pingali and G. Bilardi:
  # "A Graphical Model for Context-Free Grammar Parsing"
  def grammar()
    @grammar ||= begin
      builder = Rley::Syntax::GrammarBuilder.new do
        t_int = Rley::Syntax::Literal.new('int', /[-+]?\d+/)
        t_plus = Rley::Syntax::VerbatimSymbol.new('+')
        t_lparen = Rley::Syntax::VerbatimSymbol.new('(')
        t_rparen = Rley::Syntax::VerbatimSymbol.new(')')
        add_terminals(t_int, t_plus, t_lparen, t_rparen)
        rule 'S' => 'E'
        rule 'E' => 'int'
        rule 'E' => %w[( E + E )]
        rule 'E' => %w[E + E]
      end
      builder.grammar
    end
  end

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
      Rley::Lexical::Token.new(lexeme, terminal)
    end

    return tokens
  end
end # module
# End of file
