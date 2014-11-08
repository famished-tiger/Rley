require_relative 'state_set'
require_relative 'parse_state'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
  
    class Chart
      attr_reader(:state_sets)
    
      def initialize(startDottedRule, tokenCount)
        @state_sets = Array.new(tokenCount) {|_| StateSet.new }
        seed_state = ParseState.new(startDottedRule, 0)
        @state_sets[0].add_state(seed_state)
      end

    end # class
  
  end # module
end # module

# End of file