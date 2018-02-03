# File: expression.rb

require_relative 'abstract_method'

module Regex # This module is used as a namespace

# Abstract class. The generalization of any valid regular (sub)expression.
class Expression
  attr_accessor :begin_anchor
  attr_accessor :end_anchor

  # Constructor
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

	# Determine the matching options to apply to this object, given the options coming from the parent
	# and options that are local to this object. Local options take precedence.
	# @param theParentOptions [Hash] matching options. They are overridden by options with same name
	# that are bound to this object.
	def options(theParentOptions)
		resulting_options = theParentOptions.merge(@local_options)
		return resulting_options
	end
	
	# Template method. 
	# Purpose: Return the String representation of the expression.
	def to_str()
    result = ''
    result << prefix
    result << text_repr
    result << suffix
    
    return result
	end
  
  protected
  
  def prefix()
    begin_anchor ? begin_anchor.to_str : ''
  end
  
  def suffix()
    end_anchor ? end_anchor.to_str : ''
  end  
  
  

end # class

end # module

# End of file