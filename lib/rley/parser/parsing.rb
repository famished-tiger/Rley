require_relative 'chart'
require_relative '../ptree/parse_tree'

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
        # The last chart entry has a complete parse state
        # with the start symbol as lhs
        found = end_parse_state
        return !found.nil?
      end
      
      # Factory method. Builds a ParseTree from the parse result.
      # @return [ParseTree]
      # Algorithm:
      # set state_set_index = index of last state set in chart
      # Search the completed parse state that corresponds to the full parse
      def parse_tree()
        state_set_index = chart.state_sets.size - 1
        parse_state = end_parse_state
        full_range = { low: 0, high: state_set_index }
        start_production = chart.start_dotted_rule.production
        ptree = PTree::ParseTree.new(start_production, full_range)
        return ptree if parse_state.nil?
        loop do
          curr_dotted_item = parse_state.dotted_rule
          # Look at the symbol on left of the dot
          curr_symbol = curr_dotted_item.prev_symbol
          case curr_symbol
            when Syntax::Terminal
              state_set_index -= 1
              parse_state = predecessor_state_terminal(ptree, state_set_index, 
                parse_state)
              
            when Syntax::NonTerminal
              # Retrieve complete states
              new_states = chart[state_set_index].states_rewriting(curr_symbol)
              # TODO: make this more robust
              parse_state = new_states[0]
              curr_dotted_item = parse_state.dotted_rule
              ptree.current_node.range = { low: parse_state.origin }
              node_range =  ptree.current_node.range
              ptree.add_children(curr_dotted_item.production, node_range)
              link_node_to_token(ptree, state_set_index - 1)
              
            when NilClass
              lhs = curr_dotted_item.production.lhs
              new_states = chart[state_set_index].states_expecting(lhs)
              break if new_states.empty?
              # TODO: make this more robust
              parse_state = new_states[0]
              ptree.step_up(state_set_index)
              ptree.current_node.range = { low: parse_state.origin }
              break if ptree.root == ptree.current_node
          end
        end
        return ptree
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
      # @param aTerminal [Terminal] a terminal symbol that
      #   immediately follows a dot
      # @param aPosition [Fixnum] position in the input token sequence.
      # @param nextMapping [Proc or Lambda] code to evaluate in order to
      #   determine the "next" dotted rule for a given one.
      def scanning(aTerminal, aPosition, &nextMapping)
        curr_token = tokens[aPosition]
        return unless curr_token.terminal == aTerminal
        
        states = states_expecting(aTerminal, aPosition)
        states.each do |s|
          next_item = nextMapping.call(s.dotted_rule)
          push_state(next_item, s.origin, aPosition + 1)
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
      
      private
      
      # Retrieve full parse state.
      # After a successful parse, the last chart entry 
      # has a parse state that involves the start production and
      # has a dot positioned at the end of its rhs.
      def end_parse_state()
        start_dotted_rule = chart.start_dotted_rule
        start_production = start_dotted_rule.production
        last_chart_entry = chart.state_sets[-1]
        candidate_states = last_chart_entry.states_for(start_production)
        return candidate_states.find(&:complete?)
      end
      
      # Go to the predecessor state for the given terminal
      def predecessor_state_terminal(aParseTree, aStateSetIndex, current_state)
        aParseTree.step_back(aStateSetIndex)
        link_node_to_token(aParseTree, aStateSetIndex)
        state_set = chart[aStateSetIndex]
        state_set.predecessor_state(current_state)
      end

      
      # If the current node is a terminal node
      # then link the token to that node
      def link_node_to_token(aParseTree, aStateSetIndex)
        if aParseTree.current_node.is_a?(PTree::TerminalNode)
          a_node = aParseTree.current_node
          a_node.token = tokens[aStateSetIndex] unless a_node.token
        end
      end
      
    end # class
  end # module
end # module

# End of file
