# frozen_string_literal: true

require_relative 'ast_node'

module Rley
  module RGN
    # Abstract class for a syntax node that is the parent
    # of one or more subnodes.
    class CompositeNode < ASTNode
      # @return [Array<ASTNode>]
      attr_reader :subnodes

      # @return [Array<Syntax::MatchClosest>]
      attr_accessor :constraints

      # @param children [Array<ASTNode>] sequence of children nodes
      def initialize(children)
        super()
        @subnodes = children
        @constraints = []
      end

      def size
        subnodes.size
      end
    end # class
  end # module
end # module
