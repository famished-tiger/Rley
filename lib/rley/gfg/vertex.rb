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
        arrow = check_add_edge(anEdge)
        edges << arrow
      end
      
      # Returns true iff the vertex corresponds to an dotted item that has
      # its dot at the end of a production (i.e. is a reduced item).
      def complete?()
        return false # Default implementation
      end
      
      # Return the symbol before the dot else nil.
      def prev_symbol()
        return nil # Default implementation
      end      
      
      # Return the symbol after the dot else nil.
      def next_symbol()
        return nil # Default implementation
      end
      
      protected

      # Validation method for adding an outgoing edge to the vertex.
      # Vertices will accept an indegree and outdegree of at most one
      # unless this method is overridden in subclasses
      def check_add_edge(anEdge)
        raise StandardError, 'At most one edge accepted' unless edges.empty?
        return anEdge
      end
    end # class
  end # module
end # module

# End of file
