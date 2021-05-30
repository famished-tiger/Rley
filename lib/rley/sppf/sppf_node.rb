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
      def origin
        range.low
      end
    end # class
  end # module
end # module
# End of file
