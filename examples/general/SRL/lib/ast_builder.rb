require_relative 'ast_building'
require_relative 'regex_repr'

# The purpose of a ASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class ASTBuilder < Rley::Parser::ParseTreeBuilder
  include ASTBuilding

  Terminal2NodeClass = { }.freeze

  protected

  # Overriding method.
  # Factory method for creating a node object for the given
  # input token.
  # @param aTerminal [Terminal] Terminal symbol associated with the token
  # @param aTokenPosition [Integer] Position of token in the input stream
  # @param aToken [Token] The input token
  def new_leaf_node(aProduction, aTerminal, aTokenPosition, aToken)
    node = Rley::PTree::TerminalNode.new(aToken, aTokenPosition)

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
      when 'srl_0' # rule 'srl' => 'quantifier'
        return_first_child(aRange, theTokens, theChildren)

      when 'quantifier_0' # rule 'quantifier' => 'ONCE'
        multiplicity(1, 1)

      when 'quantifier_1' # rule 'quantifier' => 'TWICE'
        multiplicity(2, 2)

      when 'quantifier_2' # rule 'quantifier' => %w[EXACTLY count TIMES]
        reduce_quantifier_2(aProduction, aRange, theTokens, theChildren)

      when 'quantifier_3' # rule 'quantifier' => %w[BETWEEN count AND count times_suffix]
        reduce_quantifier_3(aProduction, aRange, theTokens, theChildren)

      when 'quantifier_4' # rule 'quantifier' => 'OPTIONAL'
        multiplicity(0, 1)

      when 'quantifier_5' # rule 'quantifier' => %w[ONCE OR MORE]
        multiplicity(1, :more)

      when 'quantifier_6' # rule 'quantifier' => %w[NEVER OR MORE]
        multiplicity(0, :more)

      when 'quantifier_7' # rule 'quantifier' => %w[AT LEAST count TIMES]
        reduce_quantifier_7(aProduction, aRange, theTokens, theChildren)

      when 'count_0', 'count_1'
        return_first_child(aRange, theTokens, theChildren)

      when 'times_suffix_0', 'times_suffix_1'
        nil
      else
        raise StandardError, "Don't know production #{aProduction.name}"
    end

    return node
  end

  def multiplicity(lowerBound, upperBound)
    return SRL::Regex::Multiplicity.new(lowerBound, upperBound, :greedy)
  end

  # rule 'quantifier' => %w[EXACTLY count TIMES]
  def reduce_quantifier_2(aProduction, aRange, theTokens, theChildren)
    count = theChildren[1].token.lexeme.to_i
    multiplicity(count, count)
  end

  # rule 'quantifier' => %w[BETWEEN count AND count times_suffix]
  def reduce_quantifier_3(aProduction, aRange, theTokens, theChildren)
    lower = theChildren[1].token.lexeme.to_i  
    upper = theChildren[3].token.lexeme.to_i
    multiplicity(lower, upper)
  end

  # rule 'quantifier' => %w[AT LEAST count TIMES]
  def reduce_quantifier_7(aProduction, aRange, theTokens, theChildren)
    count = theChildren[2].token.lexeme.to_i
    multiplicity(count, :more)
  end

end # class
# End of file
