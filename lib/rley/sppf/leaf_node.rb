# frozen_string_literal: true

require_relative 'sppf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Abstract class. The generalization for SPPF nodes that don't have
    # child node.
    class LeafNode < SPPFNode
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
