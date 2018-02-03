# File: wildcard.rb

require_relative 'atomic_expression'	# Access the superclass

module Regex # This module is used as a namespace

# A wildcard matches any character (except for the newline).
class Wildcard < AtomicExpression

	# Constructor
	def initialize()
		super
	end

  protected

	# Conversion method re-definition.
	# Purpose: Return the String representation of the expression.
	def text_repr()
		return '.'
	end
	
end # class
	
end # module

# End of file