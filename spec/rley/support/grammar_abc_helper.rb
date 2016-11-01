# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'

module GrammarABCHelper
  # Factory method. Creates a grammar builder for a simple grammar.
  # (based on example in N. Wirth "Compiler Construction" book, p. 6)
  def grammar_abc_builder()
    builder = Rley::Syntax::GrammarBuilder.new
    builder.add_terminals('a', 'b', 'c')
    builder.add_production('S' => 'A')
    builder.add_production('A' => %w(a A c))
    builder.add_production('A' => 'b')

    return builder
  end
end # module
# End of file
