# frozen_string_literal: true

require_relative 'composite_node'

# A syntax node representing a TOML table (akin to a Ruby Hash)
class TOMLTableNode < CompositeNode
  def add_keyval(aKeyvalNode)
    subnodes << aKeyvalNode
  end

  # @param [UnquotedKey|QuotedKey,String]
  # @return [TOMLASTNode, NilClass] the node associated with the key; otherwise nil
  def [](aKeyOrString)
    key = aKeyOrString.kind_of?(TOMLDatatype) ? aKeyOrString.value : aKeyOrString
    found = subnodes.find { |sn| sn.key.value == key }

    found&.val
  end

  def to_text
    arr = subnodes.map(&:to_text)
    arr.join(' ')
  end

  # Part of the 'visitee' role in Visitor design pattern.
  # @param visitor [TOMLASTVisitor] the visitor
  def accept(visitor)
    visitor.visit_table_node(self)
  end
end # class
