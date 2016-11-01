require_relative 'sppf_node'

module Rley # This module is used as a namespace
  module SPPF # This module is used as a namespace
    # Abstract class. The generalization for nodes that have
    # children node(s).
    class CompositeNode < SPPFNode
      # Array of sub-nodes.
      attr_reader(:subnodes)

      def initialize(aRange)
        super(aRange)
        @subnodes = []
      end


      def add_subnode(aSubnode)
        subnodes.unshift(aSubnode)
      end

      def key()
        @key ||= to_string(0)
      end
    end # class
  end # module
end # module
# End of file
