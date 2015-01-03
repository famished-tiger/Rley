require_relative 'terminal_node'
require_relative 'non_terminal_node'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class ParseTree
      # The root node of the tree
      attr_reader(:root)

      # @param theRootNode [ParseTreeNode] The root node of the parse tree.
      def initialize(theRootNode)
        @root = theRootNode
      end


      # Part of the 'visitee' role in the Visitor design pattern.
      #   A visitee is expected to accept the visit from a visitor object
      # @param aVisitor [ParseTreeVisitor] the visitor object
      def accept(aVisitor)
        aVisitor.start_visit_ptree(self)

        # Let's proceed with the visit of nodes
        root.accept(aVisitor) if root

        aVisitor.end_visit_ptree(self)
      end
    end # class
  end # module
end # module
# End of file
