# frozen_string_literal: true

require_relative 'parse_tree_node' # Load superclass

module Rley # This module is used as a namespace
  module PTree # This module is used as a namespace
    class NonTerminalNode < ParseTreeNode
      # Array of sub-nodes.
      attr_reader(:subnodes)

      def initialize(aSymbol, aRange)
        super(aSymbol, aRange)
        @subnodes = []
      end

      # Pre-pend the given subnode in front of the list of subnodes
      # @param aSubnode [ParseTreeNode-like] a child node.
      def add_subnode(aSubnode)
        subnodes.unshift(aSubnode)
      end

      # Emit a (formatted) string representation of the node.
      # Mainly used for diagnosis/debugging purposes.
      # rubocop: disable Style/StringConcatenation
      def to_string(indentation)
        connector = '+- '
        selfie = super(indentation)
        prefix = "\n" + (' ' * connector.size * indentation) + connector
        subnodes_repr = subnodes.reduce(+'') do |sub_result, subnode|
          sub_result << prefix + subnode.to_string(indentation + 1)
        end

        selfie + subnodes_repr
      end
      # rubocop: enable Style/StringConcatenation

      # Part of the 'visitee' role in Visitor design pattern.
      # @param aVisitor[ParseTreeVisitor] the visitor
      def accept(aVisitor)
        aVisitor.visit_nonterminal(self)
      end
    end # class
  end # module
end # module
# End of file
