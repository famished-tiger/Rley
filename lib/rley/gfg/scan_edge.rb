require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents an edge in a grammar flow graph
    # Responsibilities:
    # - To know the successor vertex
    class ScanEdge < Edge
      # The terminal symbol expected from the input stream
      attr_reader :terminal
      
      def initialize(thePredecessor, theSuccessor, aTerminal)
        super(thePredecessor, theSuccessor)
        @terminal = aTerminal
      end
      
      def to_s()
        " -#{terminal}-> #{successor.label}"
      end

    end # class
  end # module
end # module

# End of file