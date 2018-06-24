require_relative 'composite_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A node in a parse forest that is a child
    # of a parent node with :or refinement
    class AlternativeNode < CompositeNode
      # @return [String] GFG vertex label
      attr_reader(:label)

      # @return [Syntax::NonTerminal] Link to lhs symbol
      attr_reader(:symbol)

      # @param aVertex [GFG::ItemVertex] 
      #   A GFG vertex that corresponds to a dotted item 
      #   with the dot at the end) for the alternative under consideration.
      # @param aRange [Lexical::TokenRange] 
      #   A range of token indices corresponding to this node.
      def initialize(aVertex, aRange)
        super(aRange)
        @label = aVertex.label
        @symbol = aVertex.dotted_item.lhs
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # @return [String]
      def to_string(indentation)
        return "Alt(#{label})#{range.to_string(indentation)}"
      end
      
      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_alternative(self)
      end      
    end # class
  end # module
end # module
# End of file
