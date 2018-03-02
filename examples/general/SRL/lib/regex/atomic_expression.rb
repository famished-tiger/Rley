# File: atomic_expression.rb

require_relative 'expression' # Access the superclass

module Regex # This module is used as a namespace
  # Abstract class. A valid regular expression that
  # cannot be further decomposed into sub-expressions.
  class AtomicExpression < Expression
    # Redefined method. Return true since it may not have any child.
    def atomic?
      return true
    end
  end # class
end # module

# End of file
