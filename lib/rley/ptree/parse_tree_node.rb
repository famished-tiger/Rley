# frozen_string_literal: true

require_relative '../lexical/token_range'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class ParseTreeNode
      # Link to the grammar symbol
      attr_reader(:symbol)

      # A range of indices for tokens corresponding to the node.
      attr_reader(:range)

      def initialize(aSymbol, aRange)
        @symbol = aSymbol
        @range = Lexical::TokenRange.new(aRange)
      end

      # Notify the builder that the construction is over
      def done!
        # Do nothing
      end

      # Assign a value from given range to each  undefined range bound
      def range=(aRange)
        range.assign(aRange)
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        "#{symbol.name}#{range.to_string(indentation)}"
      end

      # Emit a short string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_s
        "#{symbol.name}#{range.to_string(0)}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        raise NotImplementedError
      end
    end # class
  end # module
end # module
# End of file
