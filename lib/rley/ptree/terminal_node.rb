require_relative 'parse_tree_node'  # Load superclass

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class TerminalNode < ParseTreeNode
      # Link to the input token
      attr(:token, true)

      def initialize(aTerminalSymbol, aRange)
        super(aTerminalSymbol, aRange)
      end
      
      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        value = token.nil? ? '(nil)' : token.lexeme
        super(indentation) + ": '#{value}'"
      end
      
      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_terminal(self)
      end
    end # class
  end # module
end # module
# End of file
