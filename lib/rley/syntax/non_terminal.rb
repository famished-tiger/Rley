# frozen_string_literal: true

require_relative 'grm_symbol' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A non-terminal symbol (sometimes called a syntactic variable) represents
    # a composition of terminal or non-terminal symbols
    class NonTerminal < GrmSymbol
      # A non-terminal symbol is nullable if it can match an empty string.
      attr_writer(:nullable)
      
      # A non-terminal symbol is undefined if no production rule in the grammar
      # has that non-terminal symbol in its left-hand side.
      attr_writer(:undefined)
      
      # A non-terminal symbol is unreachable if it cannot be reached (derived) 
      # from the start symbol.
      attr_writer(:unreachable)

      # Constructor.
      # @param aName [String] The name of the grammar symbol.
      def initialize(aName)
        super(aName)
      end

      # @return [false/true] Return true if the symbol derives
      # the empty string. As non-terminal symbol is nullable when it can
      # can match to zero input token.
      # The "nullability" of a non-terminal can practically be determined once
      # all the production rules of the grammar are specified.
      def nullable?()
        return @nullable
      end
      
      # @return [false/true] Return true if the symbol doesn't appear
      # on the left-hand side of any production rule.
      def undefined?()
        return @undefined
      end
      
      # @return [false/true] Return true if the symbol cannot be derived
      # from the start symbol.
      def unreachable?()
        return @unreachable
      end      
    end # class
  end # module
end # module
# End of file
