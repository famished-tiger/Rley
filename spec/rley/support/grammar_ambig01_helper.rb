# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/tokens/token'


module GrammarAmbig01Helper
  ########################################
  # Factory method. Define a grammar for a very simple language
  # Grammar 3: An ambiguous arithmetic expression language
  # (based on example in article on Earley's algorithm in Wikipedia)
  def grammar_ambig01_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('integer', '+', '*')
      rule 'P' => 'S'
      rule 'S' => %w[S + S]
      rule 'S' => %w[S * S]
      rule 'S' => 'L'
      rule 'L' => 'integer'
    end
    builder
  end

  # Highly simplified tokenizer implementation.
  def tokenizer_ambig01(aText, aGrammar)
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
      Rley::Tokens::Token.new(lexeme, terminal)
    end

    return tokens
  end
end # module
# End of file
