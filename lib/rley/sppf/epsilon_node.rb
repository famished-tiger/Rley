# frozen_string_literal: true

require_relative 'leaf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A leaf node in a parse forest that matches an empty
    # string from the input
    class EpsilonNode < LeafNode
      # aPosition [Integer] is the position of the token in the input stream.
      def initialize(aPosition)
        range = { low: aPosition, high: aPosition }
        super(range)
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # @return [String]
      def to_string(indentation)
        return "_#{range.to_string(indentation)}"
      end
      
      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_epsilon(self)
      end      
    end # class
  end # module
end # module
# End of file
