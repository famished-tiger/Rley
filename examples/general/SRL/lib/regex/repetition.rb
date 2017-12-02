# File: repetition.rb

require_relative "monadic_expression"	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. An unary matching operator. 
# It succeeds when the specified reptition of the child expression succeeds to match 
# the subject text in the same serial arrangement
class Repetition < MonadicExpression
	attr_reader(:multiplicity)
	
	# Constructor.
	def initialize(childExpressionToRepeat, aMultiplicity)
		super(childExpressionToRepeat)
		@multiplicity = aMultiplicity
	end
	
public
	# Conversion method re-definition.
	# Purpose: Return the String representation of the concatented expressions.
	def to_str()
		result = all_child_text() + multiplicity.to_str()
		return result
	end

end # class

end # module

# End of file