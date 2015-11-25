require_relative 'state_set'
require_relative 'parse_state'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Also called a parse table
    # A one-dimensional array with n + 1 entries (n = number of input tokens).
    class Chart
      # An array of state sets (one per input token + 1)
      attr_reader(:state_sets)
            
      # The level of trace details reported on stdout during the parse.
      # The possible values are:
      # 0: No trace output (default case)
      # 1: Show trace of scanning and completion rules
      # 2: Same as of 1 with the addition of the prediction rules
      attr_reader(:tracer)

      # @param startItems [Array] A non-empty Array of dotted items for 
      #   the start symbol.
      # @param tokenCount [Fixnum] The number of lexemes in the input to parse.
      # @param aTracer [ParseTracer] A tracer object. 
      def initialize(startItems, tokenCount, aTracer)
        @tracer = aTracer
        @state_sets = Array.new(tokenCount + 1) { |_| StateSet.new }
        startItems.each do |startDottedItem|
          push_state(startDottedItem, 0, 0, :start_rule)
        end
      end

      # The dotted item/rule used to seed the parse chart.
      # It corresponds to the start production and a dot placed
      # at the beginning of the rhs
      def start_dotted_rule()
        return self[0].states.first.dotted_rule
      end
      
      # Return the start (non-terminal) symbol of the grammar.
      def start_symbol()
        return state_sets.first.states[0].dotted_rule.lhs
      end

      # Access the state set at given position
      def [](index)
        return state_sets[index]
      end
      
      # Return the index value of the last non-empty state set.
      def last_index()
        first_empty = state_sets.find_index(&:empty?)
        if first_empty.nil?
          index = state_sets.size - 1
        else
          index = first_empty == 0 ? 0 : first_empty - 1
        end
        
        return index
      end

      # Push a parse state for the chart entry with given index
      def push_state(aDottedItem, anOrigin, anIndex, aReason)
        new_state = ParseState.new(aDottedItem, anOrigin)
        pushed = self[anIndex].push_state(new_state)
        return unless pushed && tracer.level > 0
        case aReason
          when :start_rule, :prediction
            tracer.trace_prediction(anIndex, new_state)
            
          when :scanning
             tracer.trace_scanning(anIndex, new_state)
             
          when :completion
             tracer.trace_completion(anIndex, new_state)
          else
            fail NotImplementedError, "Unknown push_state mode #{aReason}"
        end
      end
    end # class
  end # module
end # module

# End of file
