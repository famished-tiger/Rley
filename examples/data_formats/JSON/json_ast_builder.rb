require_relative 'json_ast_nodes'

# The purpose of a JSONASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class JSONASTBuilder < Rley::Parser::ParseTreeBuilder 
  Terminal2NodeClass = {
                         'false' => JSONBooleanNode,
                         'true' => JSONBooleanNode,
                         'null' => JSONNullNode,
                         'string' => JSONStringNode,
                         'number' => JSONNumberNode
                       }.freeze

  protected
  
  def return_first_child(_range, _tokens, theChildren)
    return theChildren[0]
  end

  def return_second_child(_range, _tokens, theChildren)
    return theChildren[1]
  end      

  # Overriding method.
  # Create a parse tree object with given
  # node as root node.
  def create_tree(aRootNode)
    return Rley::PTree::ParseTree.new(aRootNode)
  end

  # Overriding method.
  # Factory method for creating a node object for the given
  # input token.
  # @param terminal [Terminal] Terminal symbol associated with the token
  # @param aTokenPosition [Integer] Position of token in the input stream
  # @param aToken [Token] The input token
  def new_leaf_node(_production, terminal, aTokenPosition, aToken)
    klass = Terminal2NodeClass.fetch(terminal.name, JSONTerminalNode)
    return klass.new(aToken, aTokenPosition)
  end

  # Method to override.
  # Factory method for creating a parent node object.
  # @param aProduction [Production] Production rule
  # @param aRange [Range] Range of tokens matched by the rule
  # @param theTokens [Array] The input tokens
  # @param theChildren [Array] Children nodes (one per rhs symbol)
  def new_parent_node(aProduction, aRange, theTokens, theChildren)
    node = case aProduction.name
      when 'JSON-text_0' # rule 'JSON-text' => 'value'
        return_first_child(aRange, theTokens, theChildren)

      when /value_\d/
        return_first_child(aRange, theTokens, theChildren)

      when 'object_0'
        reduce_object_0(aProduction, aRange, theTokens, theChildren)

      when 'object_1'
        reduce_object_1(aRange, theTokens, theChildren)

      when 'member-list_0'
        reduce_member_list_0(aRange, theTokens, theChildren)

      when 'member-list_1'
        reduce_member_list_1(aProduction, aRange, theTokens, theChildren)

      when 'member_0'
        reduce_member_0(aProduction, aRange, theTokens, theChildren)

      when 'array_0'
        reduce_array_0(aProduction, aRange, theTokens, theChildren)

      when 'array_1'
        reduce_array_1(aRange, theTokens, theChildren)

      when 'array-items_0'
        reduce_array_items_0(aRange, theTokens, theChildren)

      when 'array-items_1'
        reduce_array_items_1(aProduction, aRange, theTokens, theChildren)
      else
        raise StandardError, "Don't know production #{aProduction.name}"
    end

    return node
  end
  
  # rule 'object' => %w[begin-object member-list end-object]
  def reduce_object_0(aProduction, _range, _tokens, theChildren)
    second_child = theChildren[1]
    second_child.symbol = aProduction.lhs
    return second_child
  end

  # rule 'object' => %w[begin-object end-object]
  def reduce_object_1(aProduction, _range, _tokens, _children)
    return JSONObjectNode.new(aProduction.lhs)
  end

  # rule 'member-list' => %w[member-list value-separator member]
  def reduce_member_list_0(_range, _tokens, theChildren)
    node = theChildren[0]
    node.members << theChildren.last
    return node
  end

  # rule 'member-list' => 'member'
  def reduce_member_list_1(aProduction, _range, _tokens, theChildren)
    node = JSONObjectNode.new(aProduction.lhs)
    node.members << theChildren[0]
    return node
  end

  # rule 'member' => %w[string name-separator value]
  def reduce_member_0(aProduction, _range, _tokens, theChildren)
    return JSONPair.new(theChildren[0], theChildren[2], aProduction.lhs)
  end

  # rule 'object' => %w[begin-object member-list end-object]
  def reduce_array_0(aProduction, _range, _tokens, theChildren)
    second_child = theChildren[1]
    second_child.symbol = aProduction.lhs
    return second_child  
  end

  # rule 'array' => %w[begin-array end-array]
  def reduce_array_1(_range, _tokens, _children)
    return JSONArrayNode.new
  end

  # rule 'array-items' => %w[array-items value-separator value]
  def reduce_array_items_0(_range, _tokens, theChildren)
    node = theChildren[0]
    node.children << theChildren[2]
    return node
  end
  
  #   rule 'array-items' => %w[value]
  def reduce_array_items_1(aProduction, _range, _tokens, theChildren)
    node = JSONArrayNode.new(aProduction.lhs)
    node.children << theChildren[0]
    return node
  end
end # class
# End of file
