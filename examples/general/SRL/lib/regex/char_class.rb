# File: char_class.rb

require_relative "polyadic_expression"	# Access the superclass

module Regex # This module is used as a namespace

  # Abstract class. A n-ary matching operator. 
  # It succeeds when one child expression succeeds to match the subject text.
  class CharClass < PolyadicExpression
    # These are characters with special meaning in character classes
    Metachars = ']\^-'.codepoints
    # A flag that indicates whether the character is negated
    attr_reader(:negated)
    
    # Constructor.
    def initialize(to_negate,*theChildren)
      super(theChildren)
      @negated = to_negate
    end

    protected
  
    # Conversion method re-definition.
    # Purpose: Return the String representation of the character class.
    def text_repr()
      result_children = children.inject('') do |subResult, aChild| 
        if aChild.kind_of?(Regex::Character) && Metachars.include?(aChild.codepoint)
          subResult << "\\" # Escape meta-character...
        end
        subResult << aChild.to_str() 
      end
      result = '['+ (negated ? '^' : '')  + result_children + ']'
      
      return result
    end

  end # class

end # module

# End of file