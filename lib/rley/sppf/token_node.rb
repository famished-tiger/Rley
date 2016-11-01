require_relative 'leaf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A node in a parse forest that matches exactly one
    # token from the input
    class TokenNode < LeafNode
      attr_reader(:token)

      # aPosition is the position of the token in the input stream.
      def initialize(aToken, aPosition)
        range = { low: aPosition, high: aPosition + 1 }
        super(range)
        @token = aToken
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        return "#{token.terminal.name}#{range.to_string(indentation)}"
      end

      def key()
        @key ||= to_string(0)
      end
    end # class
  end # module
end # module
# End of file
