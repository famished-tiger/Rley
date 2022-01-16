# frozen_string_literal: true

require_relative 'toml_ast_node'

# A syntax node for a TOML data literal.
# Literal nodes are leaf nodes of an AST.
class TOMLLiteralNode < TOMLASTNode
  # @return [Rley::Lexical::Position] Position of the entry in the input stream.
  attr_reader :position

  # @return [Datatype] a data value
  attr_reader :value

  # @param aPosition [Rley::Lexical::Position] Position of the entry in the input stream.
  # @param aValue [Datatype] name of grammar symbol
  def initialize(aPosition, aValue)
    super()
    @position = aPosition
    @value = aValue
  end

  # @return [String] name of grammar symbol
  def to_text
    annotation.empty? ? name : "#{name} #{annotation_to_text}"
  end

  # Abstract method (must be overriden in subclasses).
  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_literal_node(self)
  end
end # class
