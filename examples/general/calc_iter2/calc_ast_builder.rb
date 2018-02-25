require_relative 'calc_ast_nodes'

# The purpose of a CalcASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class CalcASTBuilder < Rley::ParseRep::ASTBaseBuilder

  Terminal2NodeClass = {
    # Lexical ambiguity: minus sign represents two very concepts:
    # The unary negation operator on one hand, the binary substraction operator
    'MINUS' => { 'add_operator_1' =>  Rley::PTree::TerminalNode,
                 'simple_factor_2' => CalcNegateNode,
                 'sign_1' => CalcNegateNode
               },
    'NUMBER' => CalcNumberNode,
    'PI' => CalcConstantNode,
    'E' => CalcConstantNode,
    'RESERVED' => CalcReservedNode
  }.freeze

  protected

  def terminal2node()
    Terminal2NodeClass
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

  # rule 'factor' => %w[simple_factor POWER simple_factor]]
  def reduce_factor_1(aProduction, aRange, theTokens, theChildren)
    result = PowerNode.new(theChildren[1].symbol, aRange)
    result.children << theChildren[0]
    result.children << theChildren[2]

    return result
  end

  # rule 'simple_factor' => %[sign scalar]
  def reduce_simple_factor_0(aProduction, aRange, theTokens, theChildren)
    first_child = theChildren[0]
    result = if first_child.kind_of?(CalcNegateNode)
               -theChildren[1]
             else
               theChildren[1]
             end

    return result
  end

  # rule 'simple_factor' => %w[unary_function in_parenthesis]
  def reduce_simple_factor_1(aProduction, aRange, theTokens, theChildren)
    func = CalcUnaryFunction.new(theChildren[0].symbol, aRange.low)
    func.func_name = theChildren[0].value
    func.children << theChildren[1]
    return func
  end

  # rule 'simple_factor' => %w[MINUS in_parenthesis]
  def reduce_simple_factor_2(aProduction, aRange, _tokens, theChildren)
    negation = CalcNegateNode.new(theChildren[0].symbol, aRange.low)
    negation.children << theChildren[1]
    return negation
  end

   # rule 'in_parenthesis' => %w[LPAREN expression RPAREN]
  def reduce_in_parenthesis_0(_production, _range, _tokens, theChildren)
    return_second_child(_range, _tokens, theChildren)
  end

  # rule 'add_operator' => 'PLUS'
  def reduce_add_operator_0(_production, aRange, _tokens, theChildren)
    return CalcAddNode.new(theChildren[0].symbol, aRange)
  end

  # rule 'add_operator' => 'MINUS'
  def reduce_add_operator_1(_production, aRange, _tokens, theChildren)
    return CalcSubtractNode.new(theChildren[0].symbol, aRange)
  end

  # rule 'mul_operator' => 'STAR'
  def reduce_mul_operator_0(_production, aRange, _tokens, theChildren)
    return CalcMultiplyNode.new(theChildren[0].symbol, aRange)
  end

  # rule 'mul_operator' => 'DIVIDE'
  def reduce_mul_operator_1(_production, aRange, _tokens, theChildren)
    return CalcDivideNode.new(theChildren[0].symbol, aRange)
  end
end # class
# End of file
