# frozen_string_literal: true

require_relative 'token_node'
require_relative 'non_terminal_node'
require_relative 'alternative_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # In an ambiguous grammar there are valid inputs that can result in multiple
    # parse trees. A set of parse trees is commonly referred to as a parse 
    # forest. More specifically a parse forest is a graph data 
    # structure designed to represent a set of equally syntactically correct
    # parse trees. Parse forests generated by Rley are so-called Shared Packed
    # Parse Forests (SPPF). SPPFs allow very compact representation of parse 
    # trees by sharing common sub-tree amongst the parse trees.
    class ParseForest
      # The root node of the forest
      attr_reader(:root)
      
      # A Hash with pairs of the kind node key => node
      attr_reader(:key2node)
      
      # A setter that tells that the parse is ambiguous.
      attr_writer(:is_ambiguous)


      # @param theRootNode [ParseForestNode] The root node of the parse tree.
      def initialize(theRootNode)
        @root = theRootNode
        @key2node = {}
        @is_ambiguous = false
      end
      
      # Notification that the SPPF construction is over
      def done!
        # Do nothing
      end
      
      # Returns true if the given node is present in the forest.
      def include?(aNode)
        return key2node.include?(aNode)
      end
      
      # Returns true if the parse encountered a structural ambiguity
      # (i.e. more than one parse tree for the given input)
      def ambiguous?()
        return @is_ambiguous
      end
      
      # Create an Enumerator that helps to iterate over the possible 
      # parse trees. That enumerator will generate a parse tree when 
      # called with `next` method.
      # @return [Enumerator]
      def to_ptree_enum()
        # How to implement?
        # One visits the forest => beware of dependency
        # At each visited item create a corresponding  tree node.
        # At end of visit & stack not empty
        # Re-generate another ptree
      end      

      # Part of the 'visitee' role in the Visitor design pattern.
      #   A visitee is expected to accept the visit from a visitor object
      # @param aVisitor [ParseForestVisitor] the visitor object
      def accept(aVisitor)
        aVisitor.start_visit_pforest(self)

        # Let's proceed with the visit of nodes
        root&.accept(aVisitor)

        aVisitor.end_visit_pforest(self)
      end
    end # class
  end # module
end # module
# End of file
