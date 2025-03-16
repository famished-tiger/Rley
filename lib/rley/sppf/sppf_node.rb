# frozen_string_literal: true

require_relative '../lexical/token_range'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Abstract class. The generalization for all kinds of nodes
    # occurring in a shared packed parse forest (SPPF).
    class SPPFNode
      # @return [Lexical::TokenRange]
      # A range of token indices corresponding to this node.
      attr_reader(:range)

      # Constructor
      # @param aRange [Lexical::TokenRange]
      def initialize(aRange)
        @range = Lexical::TokenRange.new(aRange)
      end

      # Return the origin, that is, the index of the
      # first token matched by this node.
      # @return [Integer]
      def origin # steep:ignore MethodBodyTypeMismatch
        range.low
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # @param indentation [Integer]
      # @return [String]
      def to_string(indentation)
        raise NotImplementedError
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseForestVisitor] the visitor
      def accept(aVisitor)
        raise NotImplementedError
      end
    end # class
  end # module
end # module
# End of file
