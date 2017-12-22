# File: abstract_method.rb

# Mix-in module. Provides the method 'abstract_method' that raises an exception
# with an appropriate message when called.
module AbstractMethod
public
	
	# Call this method in the body of your abstract methods.
	# Example:
	# require 'AbstractMethod'
	# class SomeClass
	# include AbstractMethod # To add the behaviour from the mix-in module AbstractMethod
	# ...
	# Consider that SomeClass has an abstract method called 'some_method'
	#
	# def some_method() abstract_method
	# end
	def abstract_method()
		# Determine the short class name of self
		className =  self.class.name.split(/::/).last
		
		# Retrieve the top text line of the call stack
		top_line = caller.first
		
		# Extract the calling method name
		callerNameInQuotes = top_line.scan(/`.+?$/).first
		callerName = callerNameInQuotes.gsub(/`|'/, '')	# Remove enclosing quotes
		
		# Build the error message
		error_message = "The method #{className}##{callerName} is abstract. It should be implemented in subclasses of #{className}."
		raise NotImplementedError, error_message
	end
end # module

# End of file