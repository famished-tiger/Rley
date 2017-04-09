require_relative '../tokens/token_range'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class ParseTreeNode
      # Link to the grammar symbol
      attr_reader(:symbol)

      # A range of indices for tokens corresponding to the node.
      attr_reader(:range)

      def initialize(aSymbol, aRange)
        @symbol = aSymbol
        @range = Tokens::TokenRange.new(aRange)
      end

      def range=(aRange)
        range.assign(aRange)
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        return "#{symbol.name}#{range.to_string(indentation)}"
      end

      # Emit a short string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_s()
        return "#{symbol.name}#{range.to_string(0)}"
      end
    end # class
  end # module
end # module
# End of file
