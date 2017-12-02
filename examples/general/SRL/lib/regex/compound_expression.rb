# File: compound_expression.rb

require_relative "expression"	# Access the superclass

module Regex # This module is used as a namespace

# Abstract class. An element that is part of a regular expression &  
# that has its own child sub-expressions.
class CompoundExpression < Expression
	
public
	# Redefined method. Return false since it may have one or more children.
	def atomic? 
		return false
	end
	
=begin	
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
=end

protected
	# Abstract method. Return the text representation of the child (if any)
	def all_child_text() abstract_method()
	end

end # class

end # module

# End of file