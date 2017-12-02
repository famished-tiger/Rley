# File: monadic_expression.rb

require_relative "compound_expression"	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. An element that is part of a regular expression &  
# that can have up to one child sub-expression.
class MonadicExpression < CompoundExpression
	# The (optional) child sub-expression
	attr_reader(:child)
	
	# Constructor.
	def initialize(theChild)
		super()	
		@child = theChild
	end
	
protected
	# Return the text representation of the child (if any)
	def all_child_text()
		result = child.nil? ? '' : child.to_str()
		
		return result
	end

end # class

end # module

# End of file