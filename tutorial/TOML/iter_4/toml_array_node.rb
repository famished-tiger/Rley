# frozen_string_literal: true

require_relative 'composite_node'

# A syntax node representing a TOML array
class TOMLArrayNode < CompositeNode
  def to_text
    arr = subnodes.map(&:to_text)
    arr.join(' ')
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_array_node(self)
  end
end # class
