require 'strscan'

# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'
require_relative '../../../lib/rley/lexical/token'


module GrammarArrIntHelper
  # Factory method. Creates a grammar builder for a grammar of
  # array of integers.
  # (based on the article about Earley's algorithm in Wikipedia)
  def grammar_arr_int_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('[', ']', ',', 'integer')
      rule 'P' => 'arr'
      rule 'arr' => %w([ sequence ])
      rule 'sequence' => ['list']
      rule 'sequence' => []
      rule 'list' => %w[list , integer] # Right-recursive rule
      rule 'list' => 'integer'
    end
    builder
  end

  # Basic tokenizer for array of integers
  def arr_int_tokenizer(aText, aGrammar)
    tokens = []
    scanner = StringScanner.new(aText)

    until scanner.eos?
      scanner.skip(/\s+/)
      lexeme = scanner.scan(/[\[,\]]/)
      if lexeme
        terminal = aGrammar.name2symbol[lexeme]
        tokens << Rley::Lexical::Token.new(lexeme, terminal)
        next
      end
      lexeme = scanner.scan(/^[-+]?\d+/)
      if lexeme
        terminal = aGrammar.name2symbol['integer']
        tokens << Rley::Lexical::Token.new(lexeme, terminal)
      else
        msg = "Unknown input text '#{lexeme}'"
        raise StandardError, msg
      end
    end

    return tokens
  end
end # module
# End of file
