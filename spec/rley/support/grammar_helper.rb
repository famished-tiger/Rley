# Load the builder class
require_relative '../../../lib/rley/lexical/token'


# Mixin module implementing helper methods.
module GrammarHelper
  # Create a sequence of tokens, one for each grammar symbol name.
  # Synopsis:
  #   build_token_sequence(%w(a a b c c), grm1)
  def build_token_sequence(literals, aGrammar)
    tokens = literals.map do |lexeme|
      case lexeme
        when String
          terminal = aGrammar.name2symbol[lexeme]
          Rley::Lexical::Token.new(lexeme, terminal)

        when Hash # lexeme is reality a Hash: literal => terminal name
          sub_array = lexeme.to_a
          sub_array.map do |(literal, name)|
            terminal = aGrammar.name2symbol[name]
            Rley::Lexical::Token.new(literal, terminal)
          end
      end
    end

    return tokens.flatten
  end
end # module
# End of file
