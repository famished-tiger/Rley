require_relative 'composite_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A node in a parse forest that matches exactly one
    # non-terminal symbol
    class NonTerminalNode < CompositeNode
      # Link to the non-terminal symbol
      attr_reader(:symbol)

      # Indication on how the sub-nodes contribute to the 'success'
      # of parent node. Possible values: :and, :or
      attr_accessor :refinement

      def initialize(aNonTerminal, aRange)
        super(aRange)
        @symbol = aNonTerminal
        @refinement = :and
      end
      
      def add_subnode(aSubnode)
        if refinement == :or
          subnodes << aSubnode        
        else
          super(aSubnode)
        end
      end      

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      def to_string(indentation)
        return "#{symbol.name}#{range.to_string(indentation)}"
      end

    end # class
  end # module
end # module
# End of file