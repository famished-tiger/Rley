require_relative 'vertex'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Represents a specialized vertex in a grammar flow graph 
    # that is associated to a given non-terminal symbol and
    # that may have in-degree or out-degree > 1
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class NonTerminalVertex < Vertex
      attr_reader :non_terminal
      
      def initialize(aNonTerminal)
        super()
        @non_terminal = aNonTerminal
      end
      
      protected

      # Validation method for adding an outgoing edge to the vertex.
      # A start vertex may accept an indegree and outdegree greater than one
      def check_add_edge(anEdge)
        return anEdge
      end      
    end # class
  end # module
end # module

# End of file
