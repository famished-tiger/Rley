require_relative 'token_range'

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class ParseTreeNode
      # Link to the grammar symbol
      attr_reader(:symbol)

      # A range of indices for tokens corresponding to the node.
      attr_reader(:range)


      def initialize(aSymbol, aRange)
        @symbol = aSymbol
        @range = TokenRange.new(aRange)
      end
      
      def range=(aRange)
        range.assign(aRange)
      end

    end # class
  end # module
end # module
# End of file