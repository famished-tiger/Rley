# frozen_string_literal: true

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Abstract class. Represents a vertex in a grammar flow graph
    # Responsibilities:
    # - To know its outgoing edges
    # - To know its label
    class Vertex
      # The edges linking the successor vertices to this one.
      # @return [Array<Edge>] The edge(s) linking this vertex to successor(s)
      attr_reader :edges

      # Return the object id in string format
      # @return [String]
      attr_reader :oid_str

      # Constructor to extend in subclasses.
      def initialize
        @edges = []
        @oid_str = object_id.to_s
      end

      # Determine if the vertex corresponds to an dotted item that has
      # its dot at the end of a production (i.e. is a reduced item).
      # @return [Boolean] true iff vertex corresponds to reduced item.
      def complete?
        false # Default implementation
      end

      # Returns a string containing a human-readable representation of the
      # vertex.
      # @return [String]
      def inspect
        result = +'#<'
        result << selfie
        edges.each { |e| result << e.inspect }
        result << specific_inspect
        result << '>'

        result
      end

      # Returns a string containing a human-readable representation of the
      # vertex without the edges.
      # @return [String]
      def selfie
        result = +"#{self.class.name}:#{object_id}"
        result << %( label="#{label}")
        result
      end

      # Retrieve the grammar symbol before the dot.
      # @return [GrmSymbol, NilClass] The symbol or otherwise nil.
      def prev_symbol
        nil # Default implementation
      end

      # Retrieve the grammar symbol after the dot.
      # @return [GrmSymbol, NilClass] The symbol or otherwise nil.
      def next_symbol
        nil # Default implementation
      end

      # Add an graph edge to this vertex.
      # @param anEdge [Edge] the edge to be added.
      def add_edge(anEdge)
        arrow = check_add_edge(anEdge)
        edges << arrow
      end

      # The label of this vertex.
      # It is the same as the label of the corresponding dotted item.
      # @return [String] Label for this vertex
      def label
        raise NotImplementedError
      end

      def dotted_item
        raise NotImplementedError
      end

      protected

      # Validation method for adding an outgoing edge to the vertex.
      # Vertices will accept an indegree and outdegree of at most one
      # unless this method is overridden in subclasses
      def check_add_edge(anEdge)
        raise StandardError, 'At most one edge accepted' unless edges.empty?

        anEdge
      end

      def specific_inspect
        ''
      end
    end # class
  end # module
end # module

# End of file
