# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/syntax/base_grammar_builder'
require_relative '../../../lib/support/base_tokenizer'
require_relative '../../../lib/rley/lexical/token'


# Utility class.
class GrammarPBHelper
  # Factory method. Creates a grammar for a basic arithmetic
  # expression based on example found in paper of
  # K. Pingali and G. Bilardi:
  # "A Graphical Model for Context-Free Grammar Parsing"
  def grammar
    @grammar ||= begin
      builder = Rley::Syntax::BaseGrammarBuilder.new do
        add_terminals('int', '+', '(', ')')
        rule 'S' => 'E'
        rule 'E' => 'int'
        rule 'E' => '( E + E )'
        rule 'E' => 'E + E'
      end
      builder.grammar
    end
  end

  class PB_Tokenizer < BaseTokenizer
    protected

    # rubocop: disable Lint/DuplicateBranch
    def recognize_token
      if (lexeme = scanner.scan(/[()]/)) # Single characters
        # Delimiters, separators => single character token
        build_token(lexeme, lexeme)
      elsif (lexeme = scanner.scan(/(?:\+)(?=\s|$)/)) # Isolated char
        build_token(lexeme, lexeme)
      elsif (lexeme = scanner.scan(/[+-]?[0-9]+/))
        build_token('int', lexeme)
      end
    end
    # rubocop: enable Lint/DuplicateBranch
  end # class

  # Basic tokenizer
  # @return [Array<Rley::Lexical::Token>]
  def tokenize(aText)
    tokenizer = PB_Tokenizer.new(aText)
    tokenizer.tokens
  end
end # class
# End of file
