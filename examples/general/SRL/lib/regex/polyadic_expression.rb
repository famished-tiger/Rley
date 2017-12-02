# File: polyadic_expression.rb

require_relative "compound_expression"	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. An element that is part of a regular expression &  
# that has its own child sub-expressions.
class PolyadicExpression < CompoundExpression
	# The aggregation of child elements
	attr_reader(:children)
	
	# Constructor.
	def initialize(theChildren)
		super()	
		@children = theChildren
	end
	
public
	# Append the given child to the list of children.
	# TODO: assess whether to defer to a subclass NAryExpression
	def <<(aChild)
		@children << aChild
		
		return self
	end
	
	# Build a depth-first in-order children visitor.
	# The visitor is implemented as an Enumerator.
	def df_visitor()
		root = children	# The visit will start from the children of this object
		
		visitor = Enumerator.new do |result|	# result is a Yielder
			# Initialization part: will run once
			visit_stack = [ root ]	# The LIFO queue of nodes to visit
			
			begin	# Traversal part (as a loop)
				top = visit_stack.pop()
				if top.kind_of?(Array)
					if top.empty?
						next
					else
						currChild = top.pop()
						visit_stack.push top					
					end
				else
					currChild = top
				end
				
				result << currChild		# Return the visited child
				
				unless currChild.atomic?
					children_to_enqueue = currChild.children.reverse()	# in-order traversal implies LIFO queue
					visit_stack.push(children_to_enqueue)
				end			
			end until visit_stack.empty?
		end
	end

end # class

end # module

# End of file