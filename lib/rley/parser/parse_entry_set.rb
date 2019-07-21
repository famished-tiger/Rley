require 'forwardable' # For the Delegation pattern
require 'set'

require_relative '../syntax/terminal'
require_relative '../syntax/non_terminal'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Responsibilities:
    # - To know all the parse entries in the set
    class ParseEntrySet
      extend Forwardable
      def_delegators :entries, :empty?, :size, :first, :last, :pop, :each

      # @return [Array<ParseEntry>] The array of parse entries
      attr_reader :entries
      
      # @return [Hash] A Hash with pairs { hash of ParseEntry => ParseEntry }
      attr_reader :membership      

      # Constructor.
      def initialize()
        @entries = []
        @membership = {}
        @entries4term = Hash.new { |hash, key| hash[key] = [] }
        @entries4n_term = Hash.new { |hash, key| hash[key] = [] }
      end
      
      # Returns a string containing a human-readable representation of the 
      # set of parse entries.
      # @return [String]
      def inspect()
        result = "#<#{self.class.name}:#{object_id}"
        result << ' @entries=['
        entries.each { |e| result << e.inspect }
        result << ']>'
        return result
      end

      # Access the entry at given position
      def [](index)
        return entries[index]
      end

      # Returns a Hash with pairs of the form:
      #   terminal symbol => [ parse entry expecting the terminal ]
      def entries4term(aTerminal)
        return @entries4term.fetch(aTerminal, [])
      end

      # Returns a Hash with pairs of the form:
      #   non terminal symbol => [ parse entry expecting the non-terminal ]
      def entries4n_term(aNonTerminal)
        return @entries4n_term.fetch(aNonTerminal, [])
      end

      # Append the given entry (if it isn't yet in the set)
      # to the list of parse entries
      # @param anEntry [ParseEntry] the parse entry to push.
      # @return [ParseEntry] the passed parse entry if it pushes it
      def push_entry(anEntry)
        # TODO: control overhead next line
        #match = entries.find { |entry| entry == anEntry }
        entry_key = anEntry.hash
        match = membership.fetch(entry_key, false)
        if match
          result = match
        else
          @entries << anEntry
          membership[entry_key] = anEntry
          expecting = anEntry.next_symbol
          add_lookup4symbol(anEntry) if expecting
          result = anEntry
        end

        return result
      end

      # Return an Array of Arrays of ambiguous parse entries.
      def ambiguities()
        complete_entries = entries.select(&:exit_entry?)
        return [] if complete_entries.size <= 1

        # Group parse entries by lhs symbol and origin
        groupings = complete_entries.group_by do |entry|
          entry.vertex.dotted_rule.lhs.object_id.to_s
        end

        # Retain the groups having more than one element.
        ambiguous_groups = []
        groupings.each_value do |a_group|
          ambiguous_groups << a_group if a_group.size > 1
        end

        return ambiguous_groups
      end

      # The list of distinct expected terminal symbols. An expected symbol
      # is on the left of a dot in a parse state of the parse set.
      def expected_terminals()
        return @entries4term.keys
      end

      private

      def add_lookup4symbol(anEntry)
        symb = anEntry.next_symbol
        case symb
          when Syntax::Terminal
            @entries4term[symb] << anEntry

          when Syntax::NonTerminal
            @entries4n_term[symb] << anEntry
        end
      end
    end # class
  end # module
end # module
# End of file
