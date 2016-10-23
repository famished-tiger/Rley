require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents an edge in a grammar flow graph
    # Responsibilities:
    # - To know the successor vertex
    class ShortcutEdge < Edge
      # The terminal symbol expected from the input stream
      attr_reader :nonterminal
      
      def initialize(thePredecessor, theSuccessor)
        @successor = theSuccessor
        @nonterminal = thePredecessor.next_symbol
        thePredecessor.shortcut = self
      end
      
      def to_s()
        " -#{nonterminal}-> #{successor.label}"
      end

    end # class
  end # module
end # module

# End of file