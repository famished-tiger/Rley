require_relative '../syntax/grammar'
require_relative 'grm_items_builder' # Use mix-in module



module Rley # This module is used as a namespace
  module Base # This module is used as a namespace
    # Abstract class for Earley parser.
    class BaseParser
      include GrmItemsBuilder # Mix-in for creating dotted items of grammar

      # The grammar of the language.
      # @return [Syntax::Grammar]
      attr_reader(:grammar)

      # The dotted items/rules for the productions of the grammar
      attr_reader(:dotted_items)

      # Constructor.
      # @param [Syntax::Grammar] The grammar of the language.
      def initialize(aGrammar)
        @grammar = aGrammar
        @dotted_items = build_dotted_items(grammar) # Method from mixin
      end
    end # class
  end # module
end # module

# End of file
