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
      
      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        connector = '+- '
        selfie = super(indentation)
        prefix = "\n" + (' ' * connector.size * indentation) + connector
        children_repr = children.reduce('') do |sub_result, child|
          sub_result << prefix + child.to_string(indentation + 1) 
        end
        
        return selfie + children_repr
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
