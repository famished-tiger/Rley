# File: expression.rb

require_relative 'abstract_method'

module Regex # This module is used as a namespace

# Abstract class. The generalization of any valid regular (sub)expression.
class Expression	
	def initialize()
	end
	
public
	# Abstract method. Return true iff the expression is atomic (= may not have any child).
	def atomic? abstract_method
	end

	# Abstract method. Return the number of values that match this expression.
	# [theParentOptions] an Hash of matching options. They are overridden by options with same name
	# that are bound to this object.
	def cardinality(theParentOptions) abstract_method
	end

protected
	# Determine the matching options to apply to this object, given the options coming from the parent
	# and options that are local to this object. Local options take precedence.
	# [theParentOptions] a Hash of matching options. They are overridden by options with same name
	# that are bound to this object.
	def options(theParentOptions)
		resulting_options = theParentOptions.merge(@local_options)
		return resulting_options
	end
	
	# Abstract conversion method. 
	# Purpose: Return the String representation of the expression.
	def to_str() abstract_method
	end

end # class

end # module

# End of file