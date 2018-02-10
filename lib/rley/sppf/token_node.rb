require_relative 'leaf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A SPPF node that matches exactly one
    # token from the input.
    class TokenNode < LeafNode
      # @return [Lexical::Token]
      # The input token that is represented by this parse node.
      attr_reader(:token)

      # Constructor
      # @param aToken [Lexical::Token] input token represented by this node.
      # @param aPosition [Integer] index of the token in the input stream.
      def initialize(aToken, aPosition)
        range = { low: aPosition, high: aPosition + 1 }
        super(range)
        @token = aToken
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # @param indentation [Integer]
      # @return [String]
      def to_string(indentation)
        return "#{token.terminal.name}#{range.to_string(indentation)}"
      end
    end # class
  end # module
end # module
# End of file
