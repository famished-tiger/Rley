require_relative 'parse_tree_node'  # Load superclass

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class TerminalNode < ParseTreeNode
      # Link to the input token
      attr_writer(:token)

      def initialize(aTerminalSymbol, aRange)
        super(aTerminalSymbol, aRange)
      end

    end # class
  end # module
end # module
# End of file