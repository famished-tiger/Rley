require_relative 'edge'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Specialization of an edge in a grammar flow graph
    # that has a end vertex (X.) as its head
    # and an item vertex as its tail
    
    # Responsibilities:
    # - To know the successor vertex (tail)
    class ReturnEdge < Edge
      attr_reader(:key)
    
      # Pre-condition: thePredecessor is an EndVertex
      # Pre-condition: theSuccessor is an ItemVertex
      def initialize(thePredecessor, theSuccessor)
        super(thePredecessor, theSuccessor)
        do_set_key(thePredecessor, theSuccessor)
      end
      
private
      def do_set_key(thePredecessor, theSuccessor)
        tail_d_item = theSuccessor.dotted_item
        @key = "RET_#{tail_d_item.production.object_id}_#{tail_d_item.prev_position}"
      end

    end # class
  end # module
end # module

# End of file