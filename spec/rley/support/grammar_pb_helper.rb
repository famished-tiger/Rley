# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/support/base_tokenizer'
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
        add_terminals('int', '+', '(', ')')
        rule 'S' => 'E'
        rule 'E' => 'int'
        rule 'E' => '( E + E )'
        rule 'E' => 'E + E'
      end
      builder.grammar
    end
  end

  # # Basic expression tokenizer
  # def tokenize(aText)
    # tokens = aText.scan(/\S+/).map do |lexeme|
      # case lexeme
        # when '+', '(', ')'
          # terminal = @grammar.name2symbol[lexeme]
        # when /^[-+]?\d+$/
          # terminal = @grammar.name2symbol['int']
        # else
          # msg = "Unknown input text '#{lexeme}'"
          # raise StandardError, msg
      # end
      # pos = Rley::Lexical::Position.new(1, 4) # Dummy position
      # Rley::Lexical::Token.new(lexeme, terminal, pos)
    # end

    # return tokens
  # end
  
  
  class PB_Tokenizer < BaseTokenizer

    protected

    def recognize_token()
      token = nil

      if (lexeme = scanner.scan(/[\(\)]/)) # Single characters
        # Delimiters, separators => single character token
        token = build_token(lexeme, lexeme)
      elsif (lexeme = scanner.scan(/(?:\+)(?=\s|$)/)) # Single char occurring alone
        token = build_token(lexeme, lexeme)
       elsif (lexeme = scanner.scan(/[+-]?[0-9]+/))
        token = build_token('int', lexeme)
      end
    end
  end # class

  # Basic tokenizer
  # @return [Array<Rley::Lexical::Token>]
  def tokenize(aText)
    tokenizer = PB_Tokenizer.new(aText)
    tokenizer.tokens
  end
  
end # class
# End of file
