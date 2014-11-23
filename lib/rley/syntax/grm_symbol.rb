module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Abstract class for grammar symbols.
    # A grammar symbol is an element that appears in grammar rules.
    class GrmSymbol  
      # The name of the grammar symbol
      attr_reader(:name)

      # Constructor.
      # aName [String] The name of the grammar symbol.
      def initialize(aName)
        @name = aName.dup
      end
      
      # The String representation of the grammar symbol
      # @return [String]
      def to_s()
        return name.to_s
      end
        
    end # class
  end # module
end # module

# End of file
