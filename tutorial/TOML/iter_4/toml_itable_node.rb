# frozen_string_literal: true

require_relative 'composite_node'

# A syntax node representing an inline table
class TOMLiTableNode < CompositeNode
  def to_text
    arr = subnodes.map(&:to_text)
    arr.join(' ')
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_itable_node(self)
  end
end # class
