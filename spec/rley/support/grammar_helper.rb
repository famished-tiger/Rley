# Load the builder class
require_relative '../../../lib/rley/lexical/token'


# Mixin module implementing helper methods.
module GrammarHelper
  # Create a sequence of tokens, one for each grammar symbol name.
  # Synopsis:
  #   build_token_sequence(%w(a a b c c), grm1)
  def build_token_sequence(literals, aGrammar)
    col = 1
    tokens = literals.map do |lexeme|
      pos = Rley::Lexical::Position.new(1, col)
      case lexeme
        when String
          terminal = aGrammar.name2symbol[lexeme]
          token = Rley::Lexical::Token.new(lexeme, terminal, pos)

        when Hash # lexeme is reality a Hash: literal => terminal name
          sub_array = lexeme.to_a
          sub_array.map do |(literal, name)|
            terminal = aGrammar.name2symbol[name]
            token = Rley::Lexical::Token.new(literal, terminal, pos)
          end
      end
        col += lexeme.length + 1
        token
    end

    return tokens.flatten
  end
end # module
# End of file
