# File: char_range.rb

require_relative 'polyadic_expression' # Access the superclass

module Regex # This module is used as a namespace
  # A binary expression that represents a contiguous range of characters.
  # Assumption: characters are ordered by codepoint
  class CharRange < PolyadicExpression
    # Constructor.
    # [thelowerBound] 
    #   A character that will be the lower bound value for the range.
    # [theUpperBound] 
    #   A character that will be the upper bound value for the range.
    # TODO: optimisation. Build a Character if lower bound == upper bound.
    def initialize(theLowerBound, theUpperBound)
      range = validated_range(theLowerBound, theUpperBound)
      super(range)
    end

    # Return the lower bound of the range.
    def lower()
      return children.first
    end

    # Return the upper bound of the range.
    def upper()
      return children.last
    end

    protected

    # Conversion method re-definition.
    # Purpose: Return the String representation of the concatented expressions.
    def text_repr()
      result = lower.to_str + '-' + upper.to_str

      return result
    end

    private

    # Validation method. Returns a couple of Characters.after their validation.
    def validated_range(theLowerBound, theUpperBound)
      msg = 'Character range error: lower bound is greater than upper bound.'
      raise StandardError, msg if theLowerBound.codepoint > theUpperBound.codepoint
      return [theLowerBound, theUpperBound]
    end
  end # class
end # module

# End of file
