require 'stringio'
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
      when 'srl_0' # rule 'srl' => 'pattern'
        return_first_child(aRange, theTokens, theChildren)
        
      when 'pattern_0' # rule 'pattern' => %w[pattern COMMA quantifiable]
        reduce_pattern_0(aProduction, aRange, theTokens, theChildren)

      when 'pattern_1' # rule 'pattern' => %w[pattern quantifiable]
        reduce_pattern_1(aProduction, aRange, theTokens, theChildren)        
        
      when 'pattern_2' # rule 'pattern' => 'quantifiable' 
        return_first_child(aRange, theTokens, theChildren)

      when 'quantifiable_0' # rule 'quantifiable' => 'term'
        return_first_child(aRange, theTokens, theChildren)

      when 'quantifiable_1' # rule 'quantifiable' = %w[term quantifier]
        reduce_quantifiable_1(aProduction, aRange, theTokens, theChildren)

      when 'term_0' # rule 'term' => 'atom'
        return_first_child(aRange, theTokens, theChildren)

      when 'term_1' # rule 'term' => 'alternation'
        return_first_child(aRange, theTokens, theChildren)
        
      when 'term_2' # rule 'term' => 'grouping'
        return_first_child(aRange, theTokens, theChildren)

      when 'atom_0' # rule 'atom' => 'letter_range'
        return_first_child(aRange, theTokens, theChildren)

      when 'atom_1' # rule 'atom' => 'digit_range'
        return_first_child(aRange, theTokens, theChildren)

      when 'atom_2' # rule 'atom' => 'character_class'
        return_first_child(aRange, theTokens, theChildren)

      when 'atom_3' # rule 'atom' => 'special_char'
        return_first_child(aRange, theTokens, theChildren)

      when 'atom_4' # rule 'atom' => 'literal'
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

      when 'digit_range_1' # rule 'digit_range' => 'digit_or_number'
        reduce_digit_range_1(aProduction, aRange, theTokens, theChildren)

      when 'character_class_0' # rule 'character_class' => %w[ANY CHARACTER]
        reduce_character_class_0(aProduction, aRange, theTokens, theChildren)

      when 'character_class_1' # rule 'character_class' => %w[NO CHARACTER]
        reduce_character_class_1(aProduction, aRange, theTokens, theChildren)

      when 'character_class_2' # rule 'character_class' => 'WHITESPACE'
        reduce_character_class_2(aProduction, aRange, theTokens, theChildren)

      when 'character_class_3' # rule 'character_class' => %w[NO WHITESPACE]
        reduce_character_class_3(aProduction, aRange, theTokens, theChildren)

      when 'character_class_4' # rule 'character_class' => 'ANYTHING'
        reduce_character_class_4(aProduction, aRange, theTokens, theChildren)

       when 'character_class_5' # rule 'character_class' => %w[ONE OF STRING_LIT]
        reduce_character_class_5(aProduction, aRange, theTokens, theChildren)

      when 'special_char_0' # rule 'special_char' => 'TAB'
        reduce_special_char_0(aProduction, aRange, theTokens, theChildren)

      when 'special_char_1' # rule 'special_char' => 'BACKSLASH'
        reduce_special_char_1(aProduction, aRange, theTokens, theChildren)

      when 'special_char_2' # rule 'special_char' => %w[NEW LINE]
        reduce_special_char_2(aProduction, aRange, theTokens, theChildren)

      when 'literal_0' # rule 'literal' => %[LITERALLY STRING_LIT]
        reduce_literal_0(aProduction, aRange, theTokens, theChildren)

      # rule 'alternation' => %w[ANY OF LPAREN alternatives RPAREN]
      when 'alternation_0'
        reduce_alternation_0(aProduction, aRange, theTokens, theChildren)

      # rule 'alternatives' => %w[alternatives COMMA quantifiable]
      when 'alternatives_0'
        reduce_alternatives_0(aProduction, aRange, theTokens, theChildren)

      # rule 'alternatives' => %w[alternatives quantifiable]
      when 'alternatives_1'
        reduce_alternatives_1(aProduction, aRange, theTokens, theChildren)

      when 'alternatives_2' # rule 'alternatives' => 'quantifiable'
        reduce_alternatives_2(aProduction, aRange, theTokens, theChildren)
        
      when 'grouping' # rule 'grouping' => %w[LPAREN pattern RPAREN]
        reduce_grouping_0(aProduction, aRange, theTokens, theChildren)      

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

  def string_literal(aString, to_escape = true)
    if aString.size > 1
      chars = []
      aString.each_char do |ch|
        if to_escape && Regex::Character::MetaChars.include?(ch)
          chars << Regex::Character.new("\\")
        end
        chars << Regex::Character.new(ch)
      end
      result = Regex::Concatenation.new(*chars)
    else
        if to_escape && Regex::Character::MetaChars.include?(aString)
          result = Regex::Concatenation.new(Regex::Character.new("\\"), 
            Regex::Character.new(aString))
        else
          result = Regex::Character.new(aString)
        end    
    end

    return result
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

  def char_shorthand(shortName)
    Regex::CharShorthand.new(shortName)
  end

  def wildcard()
    Regex::Wildcard.new
  end

  def repetition(expressionToRepeat, aMultiplicity)
    return Regex::Repetition.new(expressionToRepeat, aMultiplicity)
  end
  
  # rule 'pattern' => %w[pattern COMMA quantifiable]
  def reduce_pattern_0(aProduction, aRange, theTokens, theChildren)
    return Regex::Concatenation.new(theChildren[0], theChildren[2])
  end

  # rule 'pattern' => %w[pattern quantifiable]
  def reduce_pattern_1(aProduction, aRange, theTokens, theChildren)
    return Regex::Concatenation.new(theChildren[0], theChildren[1])
  end

  # rule 'quantifiable' => %w[term quantifier]
  def reduce_quantifiable_1(aProduction, aRange, theTokens, theChildren)
    quantifier = theChildren.last
    term = theChildren.first
    repetition(term, quantifier)
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
    char_shorthand('d')
  end

  # rule 'character_class' => %w[ANY CHARACTER]
  def reduce_character_class_0(aProduction, aRange, theTokens, theChildren)
    char_shorthand('w')
  end

  # rule 'character_class' => %w[NO CHARACTER]
  def reduce_character_class_1(aProduction, aRange, theTokens, theChildren)
    char_shorthand('W')
  end

  # rule 'character_class' => 'WHITESPACE'
  def reduce_character_class_2(aProduction, aRange, theTokens, theChildren)
    char_shorthand('s')
  end

  # rule 'character_class' => %w[NO WHITESPACE]
  def reduce_character_class_3(aProduction, aRange, theTokens, theChildren)
    char_shorthand('S')
  end

  # rule 'character_class' => 'ANYTHING'
  def reduce_character_class_4(aProduction, aRange, theTokens, theChildren)
    wildcard
  end

  # rule 'character_class' => %w[ONE OF STRING_LIT]
  def reduce_character_class_5(aProduction, aRange, theTokens, theChildren)
    raw_literal = theChildren[-1].token.lexeme.dup
    alternatives = raw_literal.chars.map { |ch| Regex::Character.new(ch) }
    return Regex::CharClass.new(false, *alternatives) # TODO check other implementations
  end

  # rule 'special_char' => 'TAB'
  def reduce_special_char_0(aProduction, aRange, theTokens, theChildren)
    Regex::Character.new('\t')
  end

  # rule 'special_char' => 'BACKSLASH'
  def reduce_special_char_1(aProduction, aRange, theTokens, theChildren)
    Regex::Character.new('\\')
  end

  # rule 'special_char' => %w[NEW LINE]
  def reduce_special_char_2(aProduction, aRange, theTokens, theChildren)
    # TODO: control portability
    Regex::Character.new('\n')
  end

  # rule 'literal' => %[LITERALLY STRING_LIT]
  def reduce_literal_0(aProduction, aRange, theTokens, theChildren)
    # What if literal is empty?...

    raw_literal = theChildren[-1].token.lexeme.dup
    return string_literal(raw_literal)
  end
  
  # rule 'alternation' => %w[ANY OF LPAREN alternatives RPAREN]
  def reduce_alternation_0(aProduction, aRange, theTokens, theChildren)
    return Regex::Alternation.new(*theChildren[3])
  end

  # rule 'alternatives' => %w[alternatives COMMA quantifiable]
  def reduce_alternatives_0(aProduction, aRange, theTokens, theChildren)
    return theChildren[0] << theChildren[-1]
  end

  # rule 'alternatives' => %w[alternatives quantifiable]
  def reduce_alternatives_1(aProduction, aRange, theTokens, theChildren)
    return theChildren[0] << theChildren[-1]
  end
  
  # rule 'alternatives' => 'quantifiable'
  def reduce_alternatives_2(aProduction, aRange, theTokens, theChildren)
    return [theChildren.last]
  end
  
  # rule 'grouping' => %w[LPAREN pattern RPAREN]
  def reduce_grouping_0(aProduction, aRange, theTokens, theChildren)
    return Regex::NonCapturingGroup.new(theChildren[1])  
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
