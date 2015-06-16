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
      def predecessor_state(aParseState)
        if aParseState.dotted_rule.prev_position.nil?
          fail StandardError, "#{aParseState}"
        else
          candidate = states.find { |s| s.precedes?(aParseState) }
        end
        
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

      private

      def include?(aState)
        # TODO: make it better than linear search
        return states.include?(aState)
      end
    end # class
  end # module
end # module
# End of file
