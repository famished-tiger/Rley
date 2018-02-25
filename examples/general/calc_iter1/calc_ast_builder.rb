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
    'NUMBER' => CalcNumberNode
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
  
  # rule 'expression' => 'simple_expression'
  def reduce_expression_0(_aProd, _range, _tokens, theChildren)
    return_first_child(_range, _tokens, theChildren)
  end

  # rule 'simple_expression' => 'term'
  def reduce_simple_expression_0(_aProd, _range, _tokens, theChildren)
    return_first_child(_range, _tokens, theChildren)
  end          

  # rule 'simple_expression' => %w[simple_expression add_operator term]
  def reduce_simple_expression_1(_production, _range, _tokens, theChildren)
    reduce_binary_operator(theChildren)
  end
  
  # rule 'term' => 'factor' 
  def reduce_term_0(_aProd, _range, _tokens, theChildren)
    return_first_child(_range, _tokens, theChildren)
  end  

  # rule 'term' => %w[term mul_operator factor]
  def reduce_term_1(_production, _range, _tokens, theChildren)
    reduce_binary_operator(theChildren)
  end
  
  # rule 'factor' => 'NUMBER'
  def reduce_factor_0(_aProd, _range, _tokens, theChildren)
    return_first_child(_range, _tokens, theChildren)
  end
  
  # # rule 'factor' => %w[LPAREN expression RPAREN]
  def reduce_factor_1(_aProd, _range, _tokens, theChildren)
    return_second_child(_range, _tokens, theChildren)
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
