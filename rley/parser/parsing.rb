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

        return !found.nil?
      end


      # Push a parse state (dotted item + origin) to the
      # chart entry with given index if it isn't yet in the chart entry.
      def push_state(aDottedItem, anOrigin, aChartIndex)
        fail StandardError, 'Dotted item may not be nil' if aDottedItem.nil?
        chart.push_state(aDottedItem, anOrigin, aChartIndex)
      end


      # This method is called when a parse state for chart entry at position
      # 'pos' expects a terminal as next symbol.
      # If the input token matches the terminal symbol then:
      # Retrieve all parse states for chart entry at 'aPosition'
      # that have the given terminal as next symbol.
      # For each s of the above states, push to chart entry aPosition + 1
      # a new state like: <next dotted rule, s.origin, aPosition + 1>
      # In other words, we place the dotted rules in the next state set
      # such that the dot appears after terminal.
      # @param Terminal [Terminal] a terminal symbol that
      #   immediately follows a dot
      # @param aPosition [Fixnum] position in the input token sequence.
      # @param nextMapping [Proc or Lambda] code to evaluate in order to
      #   determine the "next" dotted rule for a given one.
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



      # This method is called when a parse state at chart entry reaches the end
      # of a production.
      # For every state in chart[aPosition] that is complete 
      #  (i.e. of the form: { dotted_rule: X -> γ •, origin: j}),
      # Find states s in chart[j] of the form 
      #  {dotted_rule: Y -> α • X β, origin: i}
      #  In other words, rules that predicted the non-terminal X.
      # For each s, add to chart[aPosition] a state of the form
      #  { dotted_rule: Y → α X • β, origin: i})
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
