require_relative 'state_set'
require_relative 'parse_state'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # A one-dimensional array with n + 1 entries (n = number of input tokens)
    class Chart
      attr_reader(:state_sets)
    
      def initialize(startDottedRule, tokenCount)
        @state_sets = Array.new(tokenCount + 1) {|_| StateSet.new }
        seed_state = ParseState.new(startDottedRule, 0)
        @state_sets[0].add_state(seed_state)
      end
      
      # Access the state set at given position
      def [](index)
        return state_sets[index]
      end

    end # class
  
  end # module
end # module

# End of file