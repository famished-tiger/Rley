# frozen_string_literal: true

require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Specialization of an edge in a grammar flow graph
    # that is taken as a consequence of a scan rule.
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
