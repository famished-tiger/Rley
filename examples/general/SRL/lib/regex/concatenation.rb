# File: concatenation.rb

require_relative 'polyadic_expression'	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. A n-ary matching operator.
# It succeeds when each child succeeds to match the subject text in the same
# serial arrangement than defined by this concatenation.
class Concatenation < PolyadicExpression

	# Constructor.
	def initialize(*theChildren)
		super(theChildren)
	end

  protected

	# Conversion method re-definition.
	# Purpose: Return the String representation of the concatented expressions.
	def text_repr()
		result = children.inject('') { |result, aChild|
			result << aChild.to_str()
		}

		return result
	end

end # class

end # module

# End of file