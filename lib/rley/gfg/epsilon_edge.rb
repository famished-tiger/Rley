# frozen_string_literal: true

require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Represents an edge in a grammar flow graph
    # without change of the position in the input stream.
    # Responsibilities:
    # - To know the successor vertex
    class EpsilonEdge < Edge
      # The destination vertex of the edge .
      attr_reader :successor

      def initialize(thePredecessor, theSuccessor)
        super(thePredecessor, theSuccessor)
      end
    end # class
  end # module
end # module

# End of file
