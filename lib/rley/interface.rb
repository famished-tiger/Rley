# frozen_string_literal: true

require_relative './notation/grammar_builder'

module Rley # Module used as a namespace
  # Factory method.
  # A grammar builder constructs a Rley grammar piece by piece
  # from DSL instructions in a provided code block.
  # @param aBlock [Proc] a code block
  # @return [Rley::Notation::GrammarBuilder] An object that builds a grammar.
  def self.grammar_builder(&aBlock)
    Rley::Notation::GrammarBuilder.new(&aBlock)
  end
end # module

# End of file
