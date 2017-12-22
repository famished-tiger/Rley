require_relative 'ast_building'
require_relative 'calc_ast_nodes'

# The purpose of a CalcASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class CalcASTBuilder < Rley::Parser::ParseTreeBuilder
  include ASTBuilding

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

  # Overriding method.
  # Factory method for creating a node object for the given
  # input token.
  # @param aTerminal [Terminal] Terminal symbol associated with the token
  # @param aTokenPosition [Integer] Position of token in the input stream
  # @param aToken [Token] The input token
  def new_leaf_node(aProduction, aTerminal, aTokenPosition, aToken)
    klass = Terminal2NodeClass.fetch(aTerminal.name, CalcTerminalNode)
    node = if klass
             if klass.is_a?(Hash)
              # Lexical ambiguity...
              klass = klass.fetch(aProduction.name)
             end
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
      when 'expression_0' # rule 'expression' => %w[simple_expression]
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

      when 'factor_0' # rule 'factor' => 'simple_factor'
        return_first_child(aRange, theTokens, theChildren)

      when 'factor_1' # rule 'factor' => %w[factor POWER simple_factor]
        reduce_factor_1(aProduction, aRange, theTokens, theChildren)

      when 'simple_factor_0' # rule 'simple_factor' => %[sign scalar]
        reduce_simple_factor_0(aProduction, aRange, theTokens, theChildren)

      when 'simple_factor_1'  # rule 'simple_factor' => %w[unary_function in_parenthesis]
        reduce_simple_factor_1(aProduction, aRange, theTokens, theChildren)

      when 'simple_factor_2' # rule 'simple_factor' => %w[MINUS in_parenthesis]
        reduce_simple_factor_2(aProduction, aRange, theTokens, theChildren)

      when 'simple_factor_3' # rule 'simple_factor' => 'in_parenthesis'
        return_first_child(aRange, theTokens, theChildren)

      when 'sign_0' # rule 'sign' => 'PLUS'
        return_first_child(aRange, theTokens, theChildren)

      when 'sign_1' # rule 'sign' => 'MINUS'
        return_first_child(aRange, theTokens, theChildren)

      when 'sign_2' # rule 'sign' => []
        return_epsilon(aRange, theTokens, theChildren)

      when 'scalar_0' # rule 'scalar' => 'NUMBER'
          return_first_child(aRange, theTokens, theChildren)

      when 'scalar_1' # rule 'scalar' => 'PI'
        return_first_child(aRange, theTokens, theChildren)

      when 'scalar_2' # rule 'scalar' => 'E'
        return_first_child(aRange, theTokens, theChildren)
          
      when 'unary_function_0' # rule 'unary_function' => 'RESERVED'
        return_first_child(aRange, theTokens, theChildren)
      
      when 'in_parenthesis_0' # rule 'in_parenthesis' => %w[LPAREN expression RPAREN]
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
  def reduce_simple_factor_2(aProduction, aRange, theTokens, theChildren)
    negation = CalcNegateNode.new(theChildren[0].symbol, aRange.low)
    negation.children << theChildren[1]
    return negation
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
