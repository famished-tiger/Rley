require_relative 'grm_symbol' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace

    # A non-terminal symbol (sometimes called a syntactic variable) represents
    # a composition of terminal or non-terminal symbols
    class NonTerminal < GrmSymbol

      def initialize(aName)
        super(aName)
      end
    end # class

  end # module
end # module

# End of file
