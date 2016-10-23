# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'


module GrammarSPPFHelper
  # Factory method. Creates a grammar builder for a
  # grammar described in paper from Elisabeth Scott
  # "SPPF-Style Parsing From Earley Recognizers" in
  # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
  # contains a hidden left recursion and a cycle
  def grammar_sppf_builder()
    builder = Rley::Syntax::GrammarBuilder.new
    builder.add_terminals('a', 'b')
    builder.add_production('Phi' => %'S')
    builder.add_production('S' => %w[A T])
    builder.add_production('S' => %w[a T])
    builder.add_production('A' => 'a')
    builder.add_production('A' => %w[B A])
    builder.add_production('B' => [])
    builder.add_production('T' => %w( b b b))

    return builder
  end
   
end # module