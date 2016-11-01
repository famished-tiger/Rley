require_relative '../syntax/grammar'
require_relative 'grm_items_builder' # Use mix-in module
require_relative 'parse_tracer'
require_relative 'parsing'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Abstract class for Earley parser.
    class BaseParser
      include GrmItemsBuilder # Mix-in for creating dotted items of grammar

      # The grammar of the language.
      attr_reader(:grammar)

      # The dotted items/rules for the productions of the grammar
      attr_reader(:dotted_items)


      def initialize(aGrammar)
        @grammar = aGrammar
        @dotted_items = build_dotted_items(grammar) # Method from mixin
      end
    end # class
  end # module
end # module

# End of file
