# frozen_string_literal: true

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

      # Append the given state (if it isn't yet in the set)
      # to the list of states
      # @param aState [ParseState] the state to push.
      # @return [TrueClass/FalseClass] true when the state is really added
      def push_state(aState)
        if include?(aState)
          result = false
        else
          @states << aState
          result = true
        end

        return result
      end

      # The list of ParseState that expect the given symbol.
      # @param aSymbol [GrmSymbol] the expected symbol
      #   (=on the right of the dot)
      def states_expecting(aSymbol)
        return states.select { |s| s.dotted_rule.next_symbol == aSymbol }
      end

      # The list of complete ParseState that have the given non-terminal
      # symbol as the lhs of their production.
      def states_rewriting(aNonTerm)
        return states.select do |s|
          (s.dotted_rule.production.lhs == aNonTerm) && s.complete?
        end
      end

      # The list of ParseState that involve the given production
      def states_for(aProduction)
        return states.select { |s| s.dotted_rule.production == aProduction }
      end

      # Retrieve the parse state that is the predecessor of the given one.
      def predecessor_state(aPState)
        dotted_rule = aPState.dotted_rule
        raise StandardError, aPState.to_s unless dotted_rule.prev_position

        candidate = states.find { |s| s.precedes?(aPState) }
        return candidate
      end

      # The list of distinct expected terminal symbols. An expected symbol
      # is on the left of a dot in a parse state of the parse set.
      def expected_terminals()
        expecting_terminals = states.select do |s|
          s.dotted_rule.next_symbol.kind_of?(Rley::Syntax::Terminal)
        end

        terminals = expecting_terminals.map { |s| s.dotted_rule.next_symbol }
        return terminals.uniq
      end

      # Return an Array of Arrays of ambiguous parse states.
      def ambiguities()
        complete_states = states.select(&:complete?)
        return [] if complete_states.size <= 1

        # Group parse state by lhs symbol and origin
        groupings = complete_states.group_by do |st|
          st.dotted_rule.lhs.object_id.to_s
        end

        # Retain the groups having more than one element.
        ambiguous_groups = []
        groupings.each_value do |a_group|
          ambiguous_groups << a_group if a_group.size > 1
        end

        return ambiguous_groups
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
