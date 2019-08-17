# frozen_string_literal: true

require_relative 'sppf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Abstract class. The generalization for nodes that have
    # children node(s).
    class CompositeNode < SPPFNode
      # @return [Array<SPFFNode>] Sub-nodes (children).
      attr_reader(:subnodes)
      
      alias children subnodes      

      # Constructor
      # @param aRange [Lexical::TokenRange]      
      def initialize(aRange)
        super(aRange)
        @subnodes = []
      end

      # Add a sub-node (child) to this one.
      # @param aSubnode [SPPFNode]
      def add_subnode(aSubnode)
        subnodes.unshift(aSubnode)
      end
      
      # @return [String] a text representation of the node.
      def inspect()
        key
      end      

      # @return [String]
      def key()
        @key ||= to_string(0)
      end
    end # class
  end # module
end # module
# End of file
