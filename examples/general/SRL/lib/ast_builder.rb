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
      when 'srl_0' # rule 'srl' => 'term'
        return_first_child(aRange, theTokens, theChildren)

      when 'term_0' # rule 'term' => 'atom'
        return_first_child(aRange, theTokens, theChildren)

      when 'term_1' # rule 'term' => %w[atom quantifier]
        reduce_term_1(aProduction, aRange, theTokens, theChildren)

      when 'atom_0' # rule 'atom' => 'letter_range'
        return_first_child(aRange, theTokens, theChildren)
        
      when 'atom_1' # rule 'atom' => 'digit_range'
        return_first_child(aRange, theTokens, theChildren)
      
      # rule 'letter_range' => %w[LETTER FROM LETTER_LIT TO LETTER_LIT]
      when 'letter_range_0' 
        reduce_letter_range_0(aProduction, aRange, theTokens, theChildren)

      #rule 'letter_range' => %w[UPPERCASE LETTER FROM LETTER_LIT TO LETTER_LIT]  
      when 'letter_range_1' 
        reduce_letter_range_1(aProduction, aRange, theTokens, theChildren)

      when 'letter_range_2' # rule 'letter_range' => 'LETTER'
        reduce_letter_range_2(aProduction, aRange, theTokens, theChildren)

      when 'letter_range_3' # rule 'letter_range' => %w[UPPERCASE LETTER]
        reduce_letter_range_3(aProduction, aRange, theTokens, theChildren)

      # rule 'digit_range' => %w[digit_or_number FROM DIGIT_LIT TO DIGIT_LIT]
      when 'digit_range_0' 
        reduce_digit_range_0(aProduction, aRange, theTokens, theChildren)

      when 'digit_range_1' #rule 'digit_range' => 'digit_or_number'
        reduce_digit_range_1(aProduction, aRange, theTokens, theChildren)

      when 'quantifier_0' # rule 'quantifier' => 'ONCE'
        multiplicity(1, 1)

      when 'quantifier_1' # rule 'quantifier' => 'TWICE'
        multiplicity(2, 2)

      when 'quantifier_2' # rule 'quantifier' => %w[EXACTLY count TIMES]
        reduce_quantifier_2(aProduction, aRange, theTokens, theChildren)

      # rule 'quantifier' => %w[BETWEEN count AND count times_suffix]
      when 'quantifier_3' 
        reduce_quantifier_3(aProduction, aRange, theTokens, theChildren)

      when 'quantifier_4' # rule 'quantifier' => 'OPTIONAL'
        multiplicity(0, 1)

      when 'quantifier_5' # rule 'quantifier' => %w[ONCE OR MORE]
        multiplicity(1, :more)

      when 'quantifier_6' # rule 'quantifier' => %w[NEVER OR MORE]
        multiplicity(0, :more)

      when 'quantifier_7' # rule 'quantifier' => %w[AT LEAST count TIMES]
        reduce_quantifier_7(aProduction, aRange, theTokens, theChildren)
      
      # rule 'digit_or_number' => 'DIGIT'
      # rule 'digit_or_number' => 'NUMER'
      when 'digit_or_number_0', 'digit_or_number_1' 
        return_first_child(aRange, theTokens, theChildren)

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

  def char_range(lowerBound, upperBound)
    # TODO fix module nesting
    lower = Regex::Character.new(lowerBound)
    upper =  Regex::Character.new(upperBound)
    return Regex::CharRange.new(lower, upper)
  end

  def char_class(toNegate, *theChildren)
    Regex::CharClass.new(toNegate, *theChildren)
  end

  def repetition(expressionToRepeat, aMultiplicity)
    return Regex::Repetition.new(expressionToRepeat, aMultiplicity)
  end

  # rule 'term' => %w[atom quantifier]
  def reduce_term_1(aProduction, aRange, theTokens, theChildren)
    quantifier = theChildren.last
    atom = theChildren.first
    repetition(atom, quantifier)
  end

  # rule 'letter_range' => %w[LETTER FROM LETTER_LIT TO LETTER_LIT]
  def reduce_letter_range_0(aProduction, aRange, theTokens, theChildren)
    lower = theChildren[2].token.lexeme
    upper =  theChildren[4].token.lexeme
    ch_range = char_range(lower, upper)
    char_class(false, ch_range)
  end

  # rule 'letter_range' => %w[UPPERCASE LETTER FROM LETTER_LIT TO LETTER_LIT]
  def reduce_letter_range_1(aProduction, aRange, theTokens, theChildren)
    lower = theChildren[3].token.lexeme
    upper =  theChildren[5].token.lexeme
    ch_range = char_range(lower.upcase, upper.upcase)
    char_class(false, ch_range)
  end

  # rule 'letter_range' => 'LETTER'
  def reduce_letter_range_2(aProduction, aRange, theTokens, theChildren)
    ch_range = char_range('a', 'z')
    char_class(false, ch_range)
  end

  #rule 'letter_range' => %w[UPPERCASE LETTER]
  def reduce_letter_range_3(aProduction, aRange, theTokens, theChildren)
    ch_range = char_range('A', 'Z')
    char_class(false, ch_range)
  end
  
  # rule 'digit_range' => %w[digit_or_number FROM DIGIT_LIT TO DIGIT_LIT]
  def reduce_digit_range_0(aProduction, aRange, theTokens, theChildren)
    reduce_letter_range_0(aProduction, aRange, theTokens, theChildren)
  end

  # rule 'digit_range' => 'digit_or_number'
  def reduce_digit_range_1(aProduction, aRange, theTokens, theChildren)
    ch_range = char_range('0', '9')
    char_class(false, ch_range)  
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
