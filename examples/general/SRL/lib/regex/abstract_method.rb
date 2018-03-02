# File: abstract_method.rb

# Mix-in module. Provides the method 'abstract_method' that raises an exception
# with an appropriate message when called.
module AbstractMethod
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
    className = self.class.name.split(/::/).last

    # Retrieve the top text line of the call stack
    top_line = caller(1..1)

    # Extract the calling method name
    callerNameInQuotes = top_line.scan(/`.+?$/).first
    callerName = callerNameInQuotes.gsub(/`|'/, '') # Remove enclosing quotes

    # Build the error message
    prefix = "The method #{className}##{callerName} is abstract."
    suffix = " It should be implemented in subclasses of #{className}."
    error_message = prefix + suffix
    raise NotImplementedError, error_message
  end
end # module

# End of file
