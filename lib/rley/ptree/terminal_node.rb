require_relative 'parse_tree_node' # Load superclass

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class TerminalNode < ParseTreeNode
      # @return [Lexical::Token] the input token
      attr_reader(:token)

      # @param aToken [Lexical::Token] Input Token object
      # @param aPos [Integer] position of the token in the input stream.      
      def initialize(aToken, aPos)
        # (major, minor) =  
        
        # Use '1.class' trick to support both Integer and Fixnum classes
        range = aPos.kind_of?(1.class) ? { low: aPos, high: aPos + 1 } : aPos
        super(aToken.terminal, range)
        @token = aToken
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        return super + ": '#{token.lexeme}'"
      end
      
      # Emit a short string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_s()
        return super + ": '#{token.lexeme}'"
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
