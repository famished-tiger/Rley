require_relative 'grm_symbol' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A terminal symbol represents a class of words in the language 
    # defined the grammar.
    class Terminal < GrmSymbol
      
      # Constructor.
      # aName [String] The name of the grammar symbol.
      def initialize(aName)
        super(aName)
        self.generative = true
      end
      
      # Return true iff the symbol is a terminal
      def terminal?()
        return true
      end
      
      # @return [false] Return true if the symbol derives
      # the empty string. As terminal symbol corresponds to a input token
      # it is by definition non-nullable.
      def nullable?() 
        false
      end
    end # class
  end # module
end # module

# End of file
