module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents an edge in a grammar flow graph. 
    # Responsibilities:
    # - To know the successor vertex
    class Edge
      # The destination vertex of the edge .
      attr_reader :successor
      
      def initialize(thePredecessor, theSuccessor)
        @successor = theSuccessor
        thePredecessor.add_edge(self)
      end

    end # class
  end # module
end # module

# End of file