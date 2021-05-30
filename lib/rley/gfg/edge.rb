# frozen_string_literal: true

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents an edge in a grammar flow graph.
    # Responsibilities:
    # - To know the successor vertex
    class Edge
      # @return [Vertex] The destination vertex of the edge .
      attr_reader :successor

      # Construct a directed edge between two given vertices
      # @param thePredecessor [Vertex]
      # @param theSuccessor [Vertex]
      def initialize(thePredecessor, theSuccessor)
        @successor = theSuccessor
        thePredecessor&.add_edge(self)
      end

      # @return [String]
      def to_s
        " --> #{successor.label}"
      end

      # Returns a string containing a human-readable representation of the
      # production.
      # @return [String]
      def inspect
        to_s
      end
    end # class
  end # module
end # module

# End of file
