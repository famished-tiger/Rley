require_relative 'terminal' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A literal is terminal symbol that matches a lexical pattern
    class Literal < Terminal
      # The exact text representation of the word.
      attr_reader(:pattern)

      def initialize(aName, aPattern)
        super(aName)
        @pattern = aPattern
      end
    end # class
  end # module
end # module

# End of file
