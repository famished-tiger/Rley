require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Specialization of an edge in a grammar flow graph
    # that has a item vertex as its head (predecessor).
    # and a start vertex (.X) as its tail (successor).
    # Responsibilities:
    # - To know the successor vertex (tail)
    class CallEdge < Edge
      attr_reader(:key)

      # Pre-condition: thePredecessor is an ItemVertex
      # Pre-condition: theSuccessor is an StartVertex
      def initialize(thePredecessor, theSuccessor)
        super(thePredecessor, theSuccessor)
        do_set_key(thePredecessor, theSuccessor)
      end

      private

      def do_set_key(thePredecessor, _theSuccessor)
        tail_d_item = thePredecessor.dotted_item
        tail_production = tail_d_item.production
        @key = "CALL_#{tail_production.object_id}_#{tail_d_item.position}"
      end
    end # class
  end # module
end # module

# End of file
