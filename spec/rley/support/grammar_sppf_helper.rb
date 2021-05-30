# frozen_string_literal: true

# Load the builder class
require_relative '../../../lib/rley/syntax/grammar_builder'


module GrammarSPPFHelper
  # Factory method. Creates a grammar builder for a
  # grammar described in paper from Elisabeth Scott
  # "SPPF-Style Parsing From Earley Recognizers" in
  # Notes in Theoretical Computer Science 203, (2008), pp. 53-67
  # contains a hidden left recursion and a cycle
  def grammar_sppf_builder
    builder = Rley::Syntax::GrammarBuilder.new do
      add_terminals('a', 'b')
      rule 'Phi' => 'S'
      rule 'S' => %w[A T]
      rule 'S' => %w[a T]
      rule 'A' => 'a'
      rule 'A' => %w[B A]
      rule 'B' => []
      rule 'T' => %w[b b b]
    end

    return builder
  end
end # module
