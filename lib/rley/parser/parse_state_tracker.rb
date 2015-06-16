module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Helper class that keeps track of the parse states used
    # while a Parsing instance is constructing a parse tree.
    class ParseStateTracker
      # The index of the current state set
      attr_reader(:state_set_index)
      
      # The current parse state
      attr_reader(:parse_state)
      
      # The already processed states from current state set
      attr_reader(:processed_states)      
      
      # Constructor. Refined variant of the inherited constructor.
      def initialize(aStateSetIndex)
        self.state_set_index = aStateSetIndex
      end
      
      # Write accessor. Sets the value of the state set index
      def state_set_index=(anIndex)
        @state_set_index = anIndex
        @processed_states = {}
      end

      # Write accessor. Set the given parse state as the current one.
      def parse_state=(aParseState)
        fail StandardError, 'Nil parse state' if aParseState.nil?
        @parse_state = aParseState
        processed_states[parse_state] = true
      end
      
      # Take the first provided state that wasn't processed yet.
      def select_state(theStates)
        a_state = theStates.find { |st| !processed_states.include?(st) }
        self.parse_state = a_state
      end
      
      # The dotted item for the current parse state.
      def curr_dotted_item()
        parse_state.dotted_rule
      end
      
      def symbol_on_left()
        return curr_dotted_item.prev_symbol
      end
      
      # Notification that one begins with the previous state set
      def to_prev_state_set()      
        self.state_set_index = state_set_index - 1
      end
    end # class
  end # module
end # module

# End of file
