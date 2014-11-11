require_relative 'state_set'
require_relative 'parse_state'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Also called a parse table
    # A one-dimensional array with n + 1 entries (n = number of input tokens).
    class Chart
      attr_reader(:state_sets)

      def initialize(startDottedItem, tokenCount)
        @state_sets = Array.new(tokenCount + 1) {|_| StateSet.new }
        add_state(startDottedItem, 0, 0)
      end

      # The dotted item/rule used to seed the parse chart.
      # It corresponds to the start production and a dot placed
      # at the beginning of the rhs
      def start_dotted_rule()
        return self[0].states.first.dotted_rule
      end

      # Access the state set at given position
      def [](index)
        return state_sets[index]
      end

      # Add a parse state for the chart entry with given index
      def add_state(aDottedItem, anOrigin, anIndex)
        new_state = ParseState.new(aDottedItem, anOrigin)
        self[anIndex].add_state(new_state)
      end

    end # class

  end # module
end # module

# End of file