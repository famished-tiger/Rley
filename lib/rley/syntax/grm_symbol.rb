module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Abstract class for grammar symbols.
    # A grammar symbol is an element that appears in grammar rules.
    class GrmSymbol
      # The name of the grammar symbol
      attr_reader(:name)

      def initialize(aName)
        @name = aName.dup
      end
    end # class
  end # module
end # module

# End of file
