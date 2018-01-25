# File: non_capturing_group.rb

require_relative "monadic_expression"	# Access the superclass

module Regex # This module is used as a namespace

  # A non-capturing group, in other word it is a pure grouping of sub-expressions
  class NonCapturingGroup < MonadicExpression
    
    # Constructor.
    # [aChildExpression]	A sub-expression to match. When successful 
    # the matching text is assigned to the capture variable.
    def initialize(aChildExpression)	
      super(aChildExpression)
    end
    
  public
    # Conversion method re-definition.
    # Purpose: Return the String representation of the captured expression.
    def to_str()
      result = '(?:' + all_child_text() + ")"
      return result
    end

  end # class

end # module

# End of file