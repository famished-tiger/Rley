require_relative 'chart'
require_relative 'parse_state_tracker'
require_relative 'parse_tree_builder'


module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    class Parsing
      attr_reader(:chart)

      # The sequence of input token to parse
      attr_reader(:tokens)

      # @param aTraceLevel [Fixnum] The specified trace level.
      # The possible values are:
      # 0: No trace output (default case)
      # 1: Show trace of scanning and completion rules
      # 2: Same as of 1 with the addition of the prediction rules
      def initialize(startDottedRule, theTokens, aTracer)
        @tokens = theTokens.dup
        @chart = Chart.new(startDottedRule, tokens.size, aTracer)
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
        state_tracker = new_state_tracker
        builder = tree_builder(state_tracker.state_set_index)

        loop do
          match_symbol = state_tracker.symbol_on_left
          # puts '--------------------'
          # puts "Active parse state: #{state_tracker.parse_state}"
          # puts "Matching symbol: #{match_symbol}"
          # puts 'Parse tree:'
          # puts builder.root.to_string(0)
        
          # Place the symbol on left of the dot in the parse tree
          done = insert_matched_symbol(state_tracker, builder)
          break if done
        end

        return builder.parse_tree
      end


      # Push a parse state (dotted item + origin) to the
      # chart entry with given index if it isn't yet in the chart entry.
      def push_state(aDottedItem, anOrigin, aChartIndex, aReason)
        fail StandardError, 'Dotted item may not be nil' if aDottedItem.nil?
        chart.push_state(aDottedItem, anOrigin, aChartIndex, aReason)
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

        states = states_expecting(aTerminal, aPosition, false)
        states.each do |s|
          next_item = nextMapping.call(s.dotted_rule)
          push_state(next_item, s.origin, aPosition + 1, :scanning)
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
        states = states_expecting(curr_lhs, curr_origin, false)
        states.each do |s|
          next_item = nextMapping.call(s.dotted_rule)
          push_state(next_item, s.origin, aPosition, :completion)
        end
      end


      # The list of ParseState from the chart entry at given position
      # that expect the given terminal
      def states_expecting(aTerminal, aPosition, toSort)
        expecting = chart[aPosition].states_expecting(aTerminal)
        return expecting if !toSort || expecting.size < 2

        # Put predicted states ahead
        (predicted, others) = expecting.partition(&:predicted?)

        # Sort state in reverse order of their origin value
        [predicted, others].each do |set|
          set.sort! { |a, b| b.origin <=> a.origin }
        end

        return predicted + others
      end

      # Retrieve the parse state that represents a complete, successful parse
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


      # Insert in a parse tree the symbol on the left of the
      # current dotted rule.
      def insert_matched_symbol(aStateTracker, aBuilder)
        # Retrieve symbol before the dot in active parse state
        match_symbol = aStateTracker.symbol_on_left

        # Retrieve tree node being processed
        tree_node = aBuilder.current_node

        done = false
        case [match_symbol.class, tree_node.class]
          when [Syntax::Terminal, PTree::TerminalNode]
            aStateTracker.to_prev_state_set
            predecessor_state_terminal(match_symbol, aStateTracker, aBuilder)

          when [NilClass, Rley::PTree::TerminalNode],
            [NilClass, PTree::NonTerminalNode]
            # Retrieve all parse states that expect the lhs
            new_states = states_expecting_lhs(aStateTracker, aBuilder)
            done = true if new_states.empty?
            # Select an unused parse state
            aStateTracker.select_state(new_states)

          when [Syntax::NonTerminal, PTree::NonTerminalNode]
            completed_state_for(match_symbol, aStateTracker, aBuilder)
        end

        done ||= aBuilder.root == aBuilder.current_node
        return done
      end

      private

      # Factory method. Creates and initializes a ParseStateTracker instance.
      def new_state_tracker()
        instance = ParseStateTracker.new(chart.last_index)
        instance.parse_state = end_parse_state

        return instance
      end


      # A terminal symbol is on the left of dot.
      # Go to the predecessor state for the given terminal
      def predecessor_state_terminal(_a_symb, aStateTracker, aTreeBuilder)
        index = aStateTracker.state_set_index
        aTreeBuilder.current_node.range = { low: index, high: index + 1 }
        link_node_to_token(aTreeBuilder, aStateTracker.state_set_index)
        unless aTreeBuilder.current_node.is_a?(PTree::TerminalNode)
          fail StandardError, 'Expected terminal node'
        end
        aTreeBuilder.move_back
        state_set = chart[aStateTracker.state_set_index]
        previous_state = state_set.predecessor_state(aStateTracker.parse_state)
        aStateTracker.parse_state = previous_state
      end


      # Retrieve a complete state with given terminal symbol as lhs.
      def completed_state_for(a_symb, aTracker, aTreeBuilder)
        new_states = chart[aTracker.state_set_index].states_rewriting(a_symb)
        aTracker.select_state(new_states)
        aTreeBuilder.range = { high: aTracker.state_set_index }
        aTreeBuilder.use_complete_state(aTracker.parse_state)
        link_node_to_token(aTreeBuilder, aTracker.state_set_index - 1)
        aTreeBuilder.move_down
      end


      def states_expecting_lhs(aStateTracker, aTreeBuilder)
        lhs = aStateTracker.curr_dotted_item.production.lhs
        new_states = states_expecting(lhs, aStateTracker.state_set_index, true)
        new_states.reject! { |st| st == aStateTracker.parse_state }
        # Filter out parse states with incompatible range
        if new_states.size > 1
          previous_node = aTreeBuilder.current_path[-3]
          new_states.select! do |parse_state|
            parse_state.dotted_rule.production.lhs == previous_node.symbol
          end
        end

        return new_states
      end

      # If the current node is a terminal node
      # then link the token to that node
      def link_node_to_token(aTreeBuilder, aStateSetIndex)
        return unless aTreeBuilder.current_node.is_a?(PTree::TerminalNode)
        return unless aTreeBuilder.current_node.token.nil?

        a_node = aTreeBuilder.current_node
        a_node.token = tokens[aStateSetIndex] unless a_node.token
      end

      # Factory method. Initializes a ParseTreeBuilder object
      def tree_builder(anIndex)
        full_range = { low: 0, high: anIndex }
        start_production = chart.start_dotted_rule.production
        return ParseTreeBuilder.new(start_production, full_range)
      end
    end # class
  end # module
end # module

# End of file
