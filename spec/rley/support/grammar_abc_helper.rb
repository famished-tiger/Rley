# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'

module GrammarABCHelper
  # Factory method. Creates a grammar builder for a simple grammar.
  # (based on example in N. Wirth "Compiler Construction" book, p. 6)
  def grammar_abc_builder()
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('a', 'b', 'c')
      rule 'S' => 'A'
      rule 'A' => 'a A c'
      rule 'A' => 'b'
    end

    return builder
  end
end # module
# End of file
