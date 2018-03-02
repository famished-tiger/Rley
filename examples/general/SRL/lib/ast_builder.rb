require 'stringio'
require_relative 'regex_repr'

# The purpose of a ASTBuilder is to build piece by piece an AST
# (Abstract Syntax Tree) from a sequence of input tokens and
# visit events produced by walking over a GFGParsing object.
# Uses the Builder GoF pattern.
# The Builder pattern creates a complex object
# (say, a parse tree) from simpler objects (terminal and non-terminal
# nodes) and using a step by step approach.
class ASTBuilder < Rley::ParseRep::ASTBaseBuilder
  Terminal2NodeClass = {}.freeze

  attr_reader :options

  protected
  
  def terminal2node()
    Terminal2NodeClass
  end

  # Overriding method.
  # Factory method for creating a node object for the given
  # input token.
  # @param aTerminal [Terminal] Terminal symbol associated with the token
  # @param aTokenPosition [Integer] Position of token in the input stream
  # @param aToken [Token] The input token
  def new_leaf_node(_production, _terminal, aTokenPosition, aToken)
    node = Rley::PTree::TerminalNode.new(aToken, aTokenPosition)

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
    elsif to_escape && Regex::Character::MetaChars.include?(aString)
      backslash = Regex::Character.new("\\")
      a_string = Regex::Character.new(aString)
      result = Regex::Concatenation.new(backslash, a_string)
    else
      result = Regex::Character.new(aString)
    end

    return result
  end

  def char_range(lowerBound, upperBound)
    # TODO fix module nesting
    lower = Regex::Character.new(lowerBound)
    upper = Regex::Character.new(upperBound)
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
  
  def begin_anchor
    return Regex::Anchor.new('^')
  end
  
  # rule('expression' => %w[pattern separator flags]).as 'flagged_expr'
  def reduce_flagged_expr(_production, aRange, theTokens, theChildren)
    @options = theChildren[2] if theChildren[2]
    return_first_child(aRange, theTokens, theChildren)
  end

  # rule('pattern' => %w[pattern separator quantifiable]).as 'pattern_sequence'
  def reduce_pattern_sequence(_production, _range, _tokens, theChildren)
    return Regex::Concatenation.new(theChildren[0], theChildren[2])
  end

  # rule('flags' => %[flags separator single_flag]).as 'flag_sequence'
  def reduce_flag_sequence(_production, _range, _tokens, theChildren)
    theChildren[0] << theChildren[2]
  end

  # rule('single_flag' => %w[CASE INSENSITIVE]).as 'case_insensitive'
  def reduce_case_insensitive(_production, _range, _tokens, _children)
    return [Regex::MatchOption.new(:IGNORECASE, true)]
  end

  # rule('single_flag' => %w[MULTI LINE]).as 'multi_line'
  def reduce_multi_line(_production, _range, _tokens, _children)
    return [Regex::MatchOption.new(:MULTILINE, true)]
  end

  # rule('single_flag' => %w[ALL LAZY]).as 'all_lazy'
  def reduce_all_lazy(_production, _range, _tokens, _children)
    return [Regex::MatchOption.new(:ALL_LAZY, true)]
  end

  # rule 'quantifiable' => %w[begin_anchor anchorable end_anchor]
  def reduce_pinned_quantifiable(_production, _range, _tokens, theChildren)
    theChildren[1].begin_anchor = theChildren[0]
    theChildren[1].end_anchor = theChildren[2]
    return theChildren[1]
  end

  # rule 'quantifiable' => %w[begin_anchor anchorable]
  def reduce_begin_anchor_quantifiable(_production, _range, _tokens, theChildren)
    theChildren[1].begin_anchor = theChildren[0]
    return theChildren[1]
  end

  # rule 'quantifiable' => %w[anchorable end_anchor]
  def reduce_end_anchor_quantifiable(_production, _range, _tokens, theChildren)
    theChildren[0].end_anchor = theChildren[1]
    return theChildren[0]
  end

  # rule 'begin_anchor' => %w[STARTS WITH]
  def reduce_starts_with(_production, _range, _tokens, _children)
    begin_anchor
  end

  # rule 'begin_anchor' => %w[BEGIN WITH]  
  def reduce_begin_with(_production, _range, _tokens, _children)
    begin_anchor
  end  

  # rule 'end_anchor' => %w[MUST END].as 'end_anchor'
  def reduce_end_anchor(_production, _range, _tokens, _children)
    return Regex::Anchor.new('$')
  end

  # rule('anchorable' => %w[assertable assertion]).as 'asserted_anchorable'
  def reduce_asserted_anchorable(_production, _range, _tokens, theChildren)
    assertion = theChildren.last
    assertion.children.unshift(theChildren[0])
    return assertion
  end

  # rule('assertion' => %w[IF FOLLOWED BY assertable]).as 'if_followed'
  def reduce_if_followed(_production, _range, _tokens, theChildren)
    return Regex::Lookaround.new(theChildren.last, :ahead, :positive)
  end

  # rule('assertion' => %w[IF NOT FOLLOWED BY assertable]).as 'if_not_followed'
  def reduce_if_not_followed(_production, _range, _tokens, theChildren)
    return Regex::Lookaround.new(theChildren.last, :ahead, :negative)
  end

  # rule('assertion' => %w[IF ALREADY HAD assertable]).as 'if_had'
  def reduce_if_had(_production, _range, _tokens, theChildren)
    return Regex::Lookaround.new(theChildren.last, :behind, :positive)
  end

  # rule('assertion' => %w[IF NOT ALREADY HAD assertable]).as 'if_not_had'
  def reduce_if_not_had(_production, _range, _tokens, theChildren)
    return Regex::Lookaround.new(theChildren.last, :behind, :negative)
  end

  # rule('assertable' => %w[term quantifier]).as 'quantified_assertable'
  def reduce_quantified_assertable(_production, _range, _tokens, theChildren)
    quantifier = theChildren[1]
    term = theChildren[0]
    repetition(term, quantifier)
  end

  # rule('letter_range' => %w[LETTER FROM LETTER_LIT TO LETTER_LIT]).as 'lowercase_from_to'
  def reduce_lowercase_from_to(_production, _range, _tokens, theChildren)
    lower = theChildren[2].token.lexeme
    upper =  theChildren[4].token.lexeme
    ch_range = char_range(lower, upper)
    char_class(false, ch_range)
  end

  # rule('letter_range' => %w[UPPERCASE LETTER FROM LETTER_LIT TO LETTER_LIT]).as 'uppercase_from_to'
  def reduce_uppercase_from_to(_production, _range, _tokens, theChildren)
    lower = theChildren[3].token.lexeme
    upper =  theChildren[5].token.lexeme
    ch_range = char_range(lower.upcase, upper.upcase)
    char_class(false, ch_range)
  end

  # rule('letter_range' => 'LETTER').as 'any_lowercase'
  def reduce_any_lowercase(_production, _range, _tokens, _children)
    ch_range = char_range('a', 'z')
    char_class(false, ch_range)
  end

  # rule('letter_range' => %w[UPPERCASE LETTER]).as 'any_uppercase'
  def reduce_any_uppercase(_production, _range, _tokens, _children)
    ch_range = char_range('A', 'Z')
    char_class(false, ch_range)
  end

  # rule('digit_range' => %w[digit_or_number FROM DIGIT_LIT TO DIGIT_LIT]).as 'digits_from_to'
  def reduce_digits_from_to(aProduction, aRange, theTokens, theChildren)
    reduce_lowercase_from_to(aProduction, aRange, theTokens, theChildren)
  end

  # rule('digit_range' => 'digit_or_number').as 'simple_digit_range'
  def reduce_simple_digit_range(_production, _range, _tokens, _children)
    char_shorthand('d')
  end

  # rule('character_class' => %w[ANY CHARACTER]).as 'any_character'
  def reduce_any_character(_production, _range, _tokens, _children)
    char_shorthand('w')
  end

  # rule('character_class' => %w[NO CHARACTER]).as 'no_character'
  def reduce_no_character(_production, _range, _tokens, _children)
    char_shorthand('W')
  end

  # rule('character_class' => 'WHITESPACE').as 'whitespace'
  def reduce_whitespace(_production, _range, _tokens, _children)
    char_shorthand('s')
  end

  # rule('character_class' => %w[NO WHITESPACE]).as 'no_whitespace'
  def reduce_no_whitespace(_production, _range, _tokens, _children)
    char_shorthand('S')
  end

  # rule('character_class' => 'ANYTHING').as 'anything'
  def reduce_anything(_production, _range, _tokens, _children)
    wildcard
  end

  # rule('alternation' => %w[ANY OF LPAREN alternatives RPAREN]).as 'any_of'
  def reduce_one_of(_production, _range, _tokens, theChildren)
    raw_literal = theChildren[-1].token.lexeme.dup
    alternatives = raw_literal.chars.map { |ch| Regex::Character.new(ch) }
    # TODO check other implementations
    return Regex::CharClass.new(false, *alternatives)
  end

  # rule('special_char' => 'TAB').as 'tab'
  def reduce_tab(_production, _range, _tokens, _children)
    Regex::Character.new('\t')
  end

  # rule('special_char' => 'BACKSLASH').as 'backslash'
  def reduce_backslash(_production, _range, _tokens, _children)
    Regex::Character.new('\\')
  end

  # rule('special_char' => %w[NEW LINE]).as 'new_line'
  def reduce_new_line(_production, _range, _tokens, _children)
    # TODO: control portability
    Regex::Character.new('\n')
  end

  # rule('literal' => %w[LITERALLY STRING_LIT]).as 'literally'
  def reduce_literally(_production, _range, _tokens, theChildren)
    # What if literal is empty?...

    raw_literal = theChildren[-1].token.lexeme.dup
    return string_literal(raw_literal)
  end

  # rule('alternation' => %w[ANY OF LPAREN alternatives RPAREN]).as 'any_of'
  def reduce_any_of(_production, _range, _tokens, theChildren)
    return Regex::Alternation.new(*theChildren[3])
  end

  # rule('alternatives' => %w[alternatives separator quantifiable]).as 'alternative_list'
  def reduce_alternative_list(_production, _range, _tokens, theChildren)
    return theChildren[0] << theChildren[-1]
  end

  # rule('alternatives' => 'quantifiable').as 'simple_alternative'
  def reduce_simple_alternative(_production, _range, _tokens, theChildren)
    return [theChildren.last]
  end

  # rule('grouping' => %w[LPAREN pattern RPAREN]).as 'grouping_parenthenses'
  def reduce_grouping_parenthenses(_production, _range, _tokens, theChildren)
    return Regex::NonCapturingGroup.new(theChildren[1])
  end

  # rule('capturing_group' => %w[CAPTURE assertable]).as 'capture'
  def reduce_capture(_production, _range, _tokens, theChildren)
    return Regex::CapturingGroup.new(theChildren[1])
  end

  # rule('capturing_group' => %w[CAPTURE assertable UNTIL assertable]).as
  #   'capture_until'
  def reduce_capture_until(_production, _range, _tokens, theChildren)
    group = Regex::CapturingGroup.new(theChildren[1])
    return Regex::Concatenation.new(group, theChildren[3])
  end

  # rule('capturing_group' => %w[CAPTURE assertable AS var_name]).as 
  #   'named_capture'
  def reduce_named_capture(_production, _range, _tokens, theChildren)
    name = theChildren[3].token.lexeme.dup
    return Regex::CapturingGroup.new(theChildren[1], name)
  end

  # rule('capturing_group' => %w[CAPTURE assertable AS var_name 
  #   UNTIL assertable]).as 'named_capture_until'
  def reduce_named_capture_until(_production, _range, _tokens, theChildren)
    name = theChildren[3].token.lexeme.dup
    group = Regex::CapturingGroup.new(theChildren[1], name)
    return Regex::Concatenation.new(group, theChildren[5])
  end
  
  # rule('quantifier' => 'ONCE').as 'once'
  def reduce_once(_production, _range, _tokens, _children)
    multiplicity(1, 1)
  end
  
  # rule('quantifier' => 'TWICE').as 'twice'
  def reduce_twice(_production, _range, _tokens, _children)
    multiplicity(2, 2)
  end  

  # rule('quantifier' => %w[EXACTLY count TIMES]).as 'exactly'
  def reduce_exactly(_production, _range, _tokens, theChildren)
    count = theChildren[1].token.lexeme.to_i
    multiplicity(count, count)
  end

  # rule('quantifier' => %w[BETWEEN count AND count times_suffix]).as
  #   'between_and'
  def reduce_between_and(_production, _range, _tokens, theChildren)
    lower = theChildren[1].token.lexeme.to_i
    upper = theChildren[3].token.lexeme.to_i
    multiplicity(lower, upper)
  end
  
  # rule('quantifier' => 'OPTIONAL').as 'optional'
  def reduce_optional(_production, _range, _tokens, _children)
    multiplicity(0, 1)
  end

  # rule('quantifier' => %w[ONCE OR MORE]).as 'once_or_more'
  def reduce_once_or_more(_production, _range, _tokens, _children)
    multiplicity(1, :more)
  end
  
  # rule('quantifier' => %w[NEVER OR MORE]).as 'never_or_more'
  def reduce_never_or_more(_production, _range, _tokens, _children)
    multiplicity(0, :more)
  end
  
  # rule('quantifier' => %w[AT LEAST count TIMES]).as 'at_least' 
  def reduce_at_least(_production, _range, _tokens, theChildren)
    count = theChildren[2].token.lexeme.to_i
    multiplicity(count, :more)
  end 
  
  # rule('times_suffix' => 'TIMES').as 'times_keyword'
  def reduce_times_keyword(_production, _range, _tokens, _children)
    return nil
  end
  
  # rule('times_suffix' => []).as 'times_dropped'
  def reduce_times_dropped(_production, _range, _tokens, _children)
    return nil
  end  
end # class
# End of file
