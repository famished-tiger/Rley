require_relative 'calc_ast_nodes'

# The purpose of a CalcASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class CalcASTBuilder < Rley::Parser::ParseTreeBuilder
  Terminal2NodeClass = {
    'NUMBER' => CalcNumberNode
  }.freeze

  protected

  def return_first_child(_range, _tokens, theChildren)
    return theChildren[0]
  end

  def return_second_child(_range, _tokens, theChildren)
    return theChildren[1]
  end

  def return_last_child(_range, _tokens, theChildren)
    return theChildren[-1]
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
  # @param aTerminal [Terminal] Terminal symbol associated with the token
  # @param aTokenPosition [Integer] Position of token in the input stream
  # @param aToken [Token] The input token
  def new_leaf_node(_production, aTerminal, aTokenPosition, aToken)
    klass = Terminal2NodeClass.fetch(aTerminal.name, CalcTerminalNode)
    node = if klass
             klass.new(aToken, aTokenPosition)
           else
             PTree::TerminalNode.new(aToken, aTokenPosition)
           end

    return node
  end

  # Method to override.
  # Factory method for creating a parent node object.
  # @param aProduction [Production] Production rule
  # @param aRange [Range] Range of tokens matched by the rule
  # @param theTokens [Array] The input tokens
  # @param theChildren [Array] Children nodes (one per rhs symbol)
  def new_parent_node(aProduction, aRange, theTokens, theChildren)
    node = case aProduction.name
      when 'expression_0' # rule 'expression' => 'simple_expression'
        return_first_child(aRange, theTokens, theChildren)

      when 'simple_expression_0' # rule 'simple_expression' => 'term'
        return_first_child(aRange, theTokens, theChildren)

      when 'simple_expression_1'
        # rule 'simple_expression' => %w[simple_expression add_operator term]
        reduce_simple_expression_1(aProduction, aRange, theTokens, theChildren)

      when 'term_0' # rule 'term' => 'factor'
        return_first_child(aRange, theTokens, theChildren)

      when 'term_1' # rule 'term' => %w[term mul_operator factor]
        reduce_term_1(aProduction, aRange, theTokens, theChildren)

      when 'factor_0' # rule 'factor' => 'NUMBER'
        return_first_child(aRange, theTokens, theChildren)

      when 'factor_1' # rule 'factor' => %w[LPAREN expression RPAREN]
        return_second_child(aRange, theTokens, theChildren)

      when 'add_operator_0' # rule 'add_operator' => 'PLUS'
        reduce_add_operator_0(aProduction, aRange, theTokens, theChildren)

      when 'add_operator_1' # rule 'add_operator' => 'MINUS'
        reduce_add_operator_1(aProduction, aRange, theTokens, theChildren)

      when 'mul_operator_0' # rule 'mul_operator' => 'STAR'
         reduce_mul_operator_0(aProduction, aRange, theTokens, theChildren)

      when 'mul_operator_1' # rule 'mul_operator' =>  'DIVIDE'
         reduce_mul_operator_1(aProduction, aRange, theTokens, theChildren)

      else
        raise StandardError, "Don't know production #{aProduction.name}"
    end

    return node
  end

  def reduce_binary_operator(theChildren)
    operator_node = theChildren[1]
    operator_node.children << theChildren[0]
    operator_node.children << theChildren[2]
    return operator_node
  end

  # rule 'simple_expression' => %w[simple_expression add_operator term]
  def reduce_simple_expression_1(_production, _range, _tokens, theChildren)
    reduce_binary_operator(theChildren)
  end

  # rule 'term' => %w[term mul_operator factor]
  def reduce_term_1(_production, _range, _tokens, theChildren)
    reduce_binary_operator(theChildren)
  end

  # rule 'add_operator' => 'PLUS'
  def reduce_add_operator_0(_production, _range, _tokens, theChildren)
    return CalcAddNode.new(theChildren[0].symbol)
  end

  # rule 'add_operator' => 'MINUS'
  def reduce_add_operator_1(_production, _range, _tokens, theChildren)
    return CalcSubtractNode.new(theChildren[0].symbol)
  end

  # rule 'mul_operator' => 'STAR'
  def reduce_mul_operator_0(_production, _range, _tokens, theChildren)
    return CalcMultiplyNode.new(theChildren[0].symbol)
  end

  # rule 'mul_operator' => 'DIVIDE'
  def reduce_mul_operator_1(_production, _range, _tokens, theChildren)
    return CalcDivideNode.new(theChildren[0].symbol)
  end
end # class
# End of file
