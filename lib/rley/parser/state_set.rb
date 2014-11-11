require 'forwardable' # Delegation

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
  
    class StateSet
      extend Forwardable
      def_delegators :states, :empty?, :size, :first, :each
      
      # The set of parse states
      attr_reader(:states)
      
    
      def initialize()
        @states = []
      end
      
      # Add the given state (if it isn't yet in the set)
      def add_state(aState)
        @states << aState unless include?(aState)
      end
      
      # The list of ParseState that expect the given terminal
      def states_expecting(aTerminal)
        return states.select { |s| s.dotted_rule.next_symbol == aTerminal }
      end
      
      # The list of ParseState that involve the given production
      def states_for(aProduction)
        return states.select { |s| s.dotted_rule.production == aProduction }
      end
      
      private
      
      def include?(aState)
        # TODO: make it better than linear search
        return states.include?(aState)
      end

    end # class
  
  end # module
end # module

# End of file