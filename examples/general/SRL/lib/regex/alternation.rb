# File: alternation.rb

require_relative 'polyadic_expression'	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. A n-ary matching operator. 
# It succeeds when one child expression succeeds to match the subject text
class Alternation < PolyadicExpression
	
	# Constructor.
	def initialize(*theChildren)
		super(theChildren)
	end

  protected

	# Conversion method re-definition.
	# Purpose: Return the String representation of the concatented expressions.
	def text_repr()
		result_children = children.map { |aChild| aChild.to_str() }
		result =  '(?:' + result_children.join('|') + ')'
		
		return result
	end

end # class

end # module

# End of file