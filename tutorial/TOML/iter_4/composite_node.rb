# frozen_string_literal: true

require_relative 'toml_ast_node'

# Abstract class for a syntax node that is the parent
# of one or more subnodes.
class CompositeNode < TOMLASTNode
  # @return [Array<TOMLASTNode>]
  attr_reader :subnodes

  # @param children [Array<ASTNode>] sequence of children nodes
  def initialize(children)
    super()
    @subnodes = children
  end

  def size
    subnodes.size
  end
end # class
