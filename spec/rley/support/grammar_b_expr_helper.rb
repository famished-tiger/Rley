# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/token'


module GrammarBExprHelper
  # Factory method. Creates a grammar builder for a basic arithmetic
  # expression grammar.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_expr_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('+', '*', 'integer')
      rule 'P' => 'S'
      rule 'S' => %w(S + M)
      rule 'S' => 'M'
      rule 'M' => %w(M * T)
      rule 'M' => 'T'
      rule 'T' => 'integer'
    end
    builder
  end

  # Basic expression tokenizer
  def expr_tokenizer(aText, aGrammar)
    tokens = aText.scan(/\S+/).map do |lexeme|
      case lexeme
        when '+', '*'
          terminal = aGrammar.name2symbol[lexeme]
        when /^[-+]?\d+$/
          terminal = aGrammar.name2symbol['integer']
        else
          msg = "Unknown input text '#{lexeme}'"
          raise StandardError, msg
      end
      Rley::Parser::Token.new(lexeme, terminal)
    end

    return tokens
  end
end # module
# End of file
