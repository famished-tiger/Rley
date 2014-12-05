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
    end # class
  end # module
end # module
# End of file