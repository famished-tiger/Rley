require_relative 'chart'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace

    class Parsing
      attr_reader(:chart)
      
      # The sequence of input token to parse
      attr_reader(:tokens)

      def initialize(startDottedRule, theTokens)
        @tokens = theTokens.dup
        @chart = Chart.new(startDottedRule, tokens.size)
      end
      
      # Return true if the parse was successful (= input tokens
      # followed the syntax specified by the grammar)
      def success?()
        # Success can be detected as follows:
        # The last chart entry has a parse state
        # that involves the start production and
        # has a dot positioned at the end of its rhs.
        
        start_dotted_rule = chart.start_dotted_rule
        start_production = start_dotted_rule.production
        last_chart_entry = chart.state_sets.last
        candidate_states = last_chart_entry.states_for(start_production)
        found = candidate_states.find(&:complete?)
        
        return ! found.nil?
      end


      # Push a parse state (dotted item + origin) to the
      # chart entry with given index if it isn't yet in the chart entry.
      def push_state(aDottedItem, anOrigin, aChartIndex)
        fail StandardError, 'Dotted item may not be nil' if aDottedItem.nil?
        chart.add_state(aDottedItem, anOrigin, aChartIndex)
      end


      # Given k is current input position
      # If a is the next symbol in the input stream,
      # for every state in S(k) of the form (X → α • a β, j),
      # add (X → α a • β, j) to S(k+1).
      def scanning(aTerminal, aPosition, &nextMapping)
        curr_token = tokens[aPosition]
        
        if curr_token.terminal == aTerminal
          states = states_expecting(aTerminal, aPosition)
          states.each do |s|
            next_item = nextMapping.call(s.dotted_rule)
            push_state(next_item, s.origin, aPosition + 1)
          end
        end
      end


      # procedure COMPLETER((B → γ•, j), k)
      # for each (A → α•Bβ, i) in chart[j] do
          # ADD-TO-SET((A → αB•β, i), chart[k])
      # end
      # Parse position reached end of production
      # For every state in S(k) of the form (X → γ •, j), 
      # find states in S(j) of the form (Y → α • X β, i) 
      # and add (Y → α X • β, i) to S(k).
      def completion(aState, aPosition, &nextMapping)
        curr_origin = aState.origin
        curr_lhs = aState.dotted_rule.lhs
        states = states_expecting(curr_lhs, curr_origin)
        states.each do |s|
          next_item = nextMapping.call(s.dotted_rule)
          push_state(next_item, s.origin, aPosition)
        end
      end


      # The list of ParseState from the chart entry at given position
      # that expect the given terminal
      def states_expecting(aTerminal, aPosition)
        return chart[aPosition].states_expecting(aTerminal)
      end

    end # class

  end # module
end # module

# End of file