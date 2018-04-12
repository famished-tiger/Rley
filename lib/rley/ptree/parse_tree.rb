require_relative 'terminal_node'
require_relative 'non_terminal_node'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    # A parse tree (a.k.a. concrete syntax tree) is a tree-based representation
    # for the parse that corresponds to the input text. In a parse tree, 
    # a node corresponds to a grammar symbol used during the parsing:
    # - a leaf node maps to a terminal symbol occurring in
    # the input, and
    # - a intermediate node maps to a non-terminal node reduced
    # during the parse. 
    # The root node corresponds to the main/start symbol of the grammar.
    class ParseTree
      # @return [ParseTreeNode] The root node of the tree.
      attr_reader(:root)

      # @param theRootNode [ParseTreeNode] The root node of the parse tree.
      def initialize(theRootNode)
        @root = theRootNode
      end
      
      # Notify the builder that the construction is over.
      # This method can be overriden
      def done!()
        @root.done!
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
