# frozen_string_literal: true

require_relative 'composite_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # A node in a parse forest that matches exactly one
    # non-terminal symbol.
    class NonTerminalNode < CompositeNode
      # @return [Syntax::NonTerminal] Link to the non-terminal symbol
      attr_reader(:symbol)

      # Indication on how the sub-nodes contribute to the 'success'
      # of parent node. Possible values: :and, :or
      attr_accessor :refinement

      # Constructor
      # @param aNonTerminal [Syntax::NonTerminal]
      # @param aRange [Lexical::TokenRange]
      def initialize(aNonTerminal, aRange)
        super(aRange)
        @symbol = aNonTerminal
        @refinement = :and
      end

      # Add a sub-node (child) to this one.
      # @param aSubnode [SPPFNode]
      def add_subnode(aSubnode)
        if refinement == :or
          subnodes << aSubnode
        else
          super(aSubnode)
        end
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # @return [String] a text representation of the node.
      def to_string(indentation)
        return "#{symbol.name}#{range.to_string(indentation)}"
      end

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_nonterminal(self)
      end
    end # class
  end # module
end # module
# End of file
