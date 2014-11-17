require_relative 'grm_symbol' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A non-terminal symbol (sometimes called a syntactic variable) represents
    # a composition of terminal or non-terminal symbols
    class NonTerminal < GrmSymbol
    
      # Constructor.
      # @param aName [String] The name of the grammar symbol.
      def initialize(aName)
        super(aName)
      end
      
      public
      
      # @return [false/true] Return true if the symbol derives
      # the empty string. As non-terminal symbol is nullable when it can
      # can match to zero input token.
      # The "nullability" of a non-terminal can practically be determined once
      # all the production rules of the grammar are specified.
      def nullable?()
        return @nullable
      end
      
      # Set the nullable flag.
      # @param aBoolean [true/false]
      def nullable=(aBoolean)
        @nullable = aBoolean
      end
      

    end # class
  end # module
end # module
# End of file
