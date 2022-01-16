# frozen_string_literal: true

require_relative 'all_ast_nodes'

# A class aimed to perform conversion from TOML to Ruby while the parse tree
# being visited.
class TOML2Ruby
  # @return [Array<Hash>] A Stack of Hash (to cope with their nesting)
  attr_reader :hash_stack

  # @return [Array<Object>] A stack for keeping of TOML data values converted into their Ruby counterparts
  attr_reader :data_stack

  # Constructor.
  def initialize
    @hash_stack = []
    @data_stack = []
  end

  # Given an abstract syntax parse tree visitor, launch the visit
  # and execute the visit events in the output stream.
  # @param aVisitor [TOMLASTVisitor]
  # @return [Hash]
  def convert(aVisitor)
    aVisitor.subscribe(self)
    aVisitor.start
    aVisitor.unsubscribe(self)
    curr_hash
  end

  def curr_hash
    hash_stack.last
  end

  def before_table_node(_tableNode, _visitor)
    @hash_stack << {}
  end

  def after_table_node(_tableNode, _visitor)
    data_stack.push curr_hash
  end

  def after_keyval_node(aKeyvalNode, _visitor)
    value = aKeyvalNode.val
    hash_stack.pop if (value.kind_of?(TOMLTableNode) || value.kind_of?(TOMLiTableNode)) && hash_stack.size > 1
    val = data_stack.pop
    key = data_stack.pop
    curr_hash[key] = val
  end

  def after_array_node(anArrayNode, _visitor)
    arr = []
    anArrayNode.subnodes.size.times do
      elem = data_stack.pop
      arr.unshift(elem)
    end
    data_stack << arr
  end

  def found_data_value(aDatatype, _visitor)
    data_stack.push(aDatatype.value)
  end

  def found_unquoted_key(anUnquotedKey, _visitor)
    data_stack.push(anUnquotedKey.value)
  end
end # class
