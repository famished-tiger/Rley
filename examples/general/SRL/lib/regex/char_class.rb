# File: char_class.rb

require_relative "polyadic_expression"	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. A n-ary matching operator. 
# It succeeds when one child expression succeeds to match the subject text
# than defined by this concatenation.
class CharClass < PolyadicExpression
	# A flag that indicates whether the character is negated
	attr_reader(:negated)
	
	# Constructor.
	def initialize(to_negate,*theChildren)
		super(theChildren)
		@negated = to_negate
	end

public
	# Conversion method re-definition.
	# Purpose: Return the String representation of the concatented expressions.
	def to_str()
		result_children = children.inject('') { |subResult, aChild| subResult << aChild.to_str() }
		result = '['+ (negated ? '^' : '')  + result_children + ']'
		
		return result
	end

end # class

end # module

# End of file