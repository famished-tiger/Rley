# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/syntax/base_grammar_builder'

module GrammarABCHelper
  # Factory method. Creates a grammar builder for a simple grammar.
  # (based on example in N. Wirth "Compiler Construction" book, p. 6)
  def grammar_abc_builder
    Rley::Syntax::BaseGrammarBuilder.new do
      add_terminals('a', 'b', 'c')
      rule 'S' => 'A'
      rule 'A' => 'a A c'
      rule 'A' => 'b'
    end
  end
end # module
# End of file
