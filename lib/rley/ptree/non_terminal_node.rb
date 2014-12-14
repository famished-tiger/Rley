require_relative 'parse_tree_node'  # Load superclass

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class NonTerminalNode < ParseTreeNode
      # Link to the input token
      attr_reader(:children)

      def initialize(aSymbol, aRange)
        super(aSymbol, aRange)
        @children = []
      end

      # @param aChildNode [ParseTreeNode-like] a child node.
      def add_child(aChildNode)
        children << aChildNode
      end
      
      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.start_visit_nonterminal(self)
        aVisitor.visit_children(self)
        aVisitor.end_visit_nonterminal(self)
      end
    end # class
  end # module
end # module
# End of file
