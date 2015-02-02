# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/parser/token'


module GrammarBExprHelper
  # Factory method. Creates a grammar builder for a basic arithmetic
  # expression grammar.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_expr_builder()
    builder = Rley::Syntax::GrammarBuilder.new
    builder.add_terminals('+', '*', 'integer')
    builder.add_production('P' => 'S')
    builder.add_production('S' => %w(S + M))
    builder.add_production('S' => 'M')
    builder.add_production('M' => %w(M * T))
    builder.add_production('M' => 'T')
    builder.add_production('T' => 'integer')
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
          fail StandardError, msg
      end
      Rley::Parser::Token.new(lexeme, terminal)
    end
    
    return tokens
  end
end # module
