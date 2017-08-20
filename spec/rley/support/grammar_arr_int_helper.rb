# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/tokens/token'


module GrammarArrIntHelper
  # Factory method. Creates a grammar builder for a grammar of
  # array of integers.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_arr_int_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('[', ']', ',', 'integer')
      rule 'P' => 'arr'
      rule 'arr' => %w( [ sequence ] )
      rule 'sequence' => ['list']
      rule 'sequence' => []
      rule 'list' => %w[list , integer]
      rule 'list' => 'integer'
    end
    builder
  end

  # Basic tokenizer for array of integers
  def arr_int_tokenizer(aText, aGrammar)
    tokens = aText.scan(/\S+/).map do |lexeme|
      case lexeme
        when '[', ']', ','
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
