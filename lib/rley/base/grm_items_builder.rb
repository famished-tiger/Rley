require_relative 'dotted_item'

module Rley # This module is used as a namespace
  module Base # This module is used as a namespace
    # Mix-in module. Builds the dotted items for a given grammar
    module GrmItemsBuilder
      # Build an array of dotted items from the productions of passed grammar.
      # @param aGrammar [Syntax::Grammar]
      # @return [Array<DottedItem>]
      def build_dotted_items(aGrammar)
        items = []
        aGrammar.rules.each do |prod|
          rhs_size = prod.rhs.size
          if rhs_size.zero?
            items << DottedItem.new(prod, 0)
          else
            items += (0..rhs_size).map { |i| DottedItem.new(prod, i) }
          end
        end

        return items
      end
    end # module
  end # module
end # module
# End of file
