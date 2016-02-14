module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents a vertex in a grammar flow graph
    # Responsibilities:
    # - To know its outgoing edges
    # - To know its label
    class Vertex
      # The edges linking the successor vertices to this one.
      attr_reader :edges
      
      def initialize()
        @edges = []
      end
      
      # Add an graph edge to this vertex
      def add_edge(anEdge)
        edges << anEdge
      end

    end # class
  end # module
end # module

# End of file
