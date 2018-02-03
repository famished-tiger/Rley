# File: capturing_group.rb

require_relative "monadic_expression"	# Access the superclass

module Regex # This module is used as a namespace

  # An association between a capture variable and an expression
  # the subject text in the same serial arrangement
  class CapturingGroup < MonadicExpression
    # The capture variable id. It is a Fixnum when the capture group gets a sequence number, 
    # a String when it is an user-defined name
    attr_reader(:id)
    
    # When true, then capturing group forbids backtracking requests from its parent expression. 
    attr_reader(:no_backtrack)
    
    # Constructor.
    # [aChildExpression]	A sub-expression to match. When successful the matching text is assigned to the capture variable.
    # [theId] The id of the capture variable.
    # [noBacktrack] A flag that specifies whether the capturing group forbids backtracking requests from its parent expression.
    def initialize(aChildExpression, theId = nil, noBacktrack = false)
      super(aChildExpression)
      @id = theId
      @no_backtrack = noBacktrack
    end
    
  public
    # Return true iff the capturing group has a name (and not )
    def named?()
      return id.kind_of?(String)
    end

    # Conversion method re-definition.
    # Purpose: Return the String representation of the captured expression.
    def to_str()
      prefix = named? ? "?<#{id}>" : ''
      atomic = no_backtrack ? '?>' : ''
      if child.is_a?(Regex::NonCapturingGroup)
        # Minor optimization
        result = '(' + atomic + prefix + child.child.to_str + ")"
      else
        result = '(' + atomic + prefix + child.to_str + ")"
      end
      return result
    end

  end # class
end # module

# End of file