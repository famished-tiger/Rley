# frozen_string_literal: true

require_relative 'parse_entry'
require_relative 'parse_entry_set'


module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Also called a parse table.
    # It is a Grammar Flow Graph implementation.
    # Assuming that n == number of input tokens,
    # the chart is an array with n + 1 entry sets.
    class GFGChart
      # @return [Array<ParseEntrySet>] entry sets (one per input token + 1)
      attr_reader(:sets)

      # @param aGFGraph [GFG::GrmFlowGraph] The GFG for the grammar in use.
      def initialize(aGFGraph)
        @sets = [ParseEntrySet.new]
        push_entry(aGFGraph.start_vertex, 0, 0, :start_rule)
      end

      # @return [Syntax::NonTerminal] the start symbol of the grammar.
      def start_symbol
        sets.first.entries[0].vertex.non_terminal
      end

      # @param index [Integer]
      # @return [ParseEntrySet] Access the entry set at given position.
      def [](index)
        sets[index]
      end

      # Return the index value of the last non-empty entry set.
      # @return [Integer]
      def last_index
        first_empty = sets.find_index(&:empty?)
        if first_empty.nil?
          sets.size - 1
        else
          first_empty.zero? ? 0 : first_empty - 1
        end
      end

      # Push a parse entry for the chart entry with given index
      # @param anIndex [Integer] The rank of the token in the input stream.
      # @return [ParseEntry] the passed parse entry if it is pushed
      def push_entry(aVertex, anOrigin, anIndex, reason)
        # puts "push_entry:"
        # puts "  aVertex #{aVertex.inspect}"
        # puts "  anOrigin: #{anOrigin}"
        # puts "  anIndex: #{anIndex}"
        # puts "  _reason: #{_reason}"
        new_entry = ParseEntry.new(aVertex, anOrigin)
        if anIndex == sets.size
          err_msg = "Internal error: unexpected push reason #{reason}"
          raise StandardError, err_msg if reason != :scan_rule

          add_entry_set
        end
        self[anIndex].push_entry(new_entry)
      end

      # Retrieve the first parse entry added to this chart
      # @return [ParseEntry]
      def initial_entry
        sets[0].first
      end

      # Retrieve the entry that corresponds to a complete and successful parse
      # @return [ParseEntry]
      def accepting_entry
        # Success can be detected as follows:
        # The last chart entry set has at least one complete parse entry
        # for the start symbol with an origin == 0

        # Retrieve all the end entries (i.e. of the form
        last_entries = sets[last_index].entries.select(&:end_entry?)
        # last_entries.each_with_index do |entry, index|
        #  if entry.nil?
        #    puts "Nil entry at index #{index}"
        #  else
        #    puts entry
        #  end
        # end

        # ... now find the end vertex for start symbol and with origin at zero.
        success_entries = last_entries.select do |entry|
          entry.origin.zero? && entry.vertex.non_terminal == start_symbol
        end

        success_entries.first
      end

      # @return [Integer] The number of states.
      def count_states
        sets.size
      end

      # @return [Integer] The total number of entries.
      def count_entries
        # rubocop: disable Lint/UselessAssignment
        sets.reduce(0) do |sub_result, a_set|
          sub_result += a_set.size
        end
      end

      # @return [Integer] The total number of edges.
      def count_edges
        sets.reduce(0) do |sub_result, a_set|
          sub_result += a_set.count_edges
        end
      end
      # rubocop: enable Lint/UselessAssignment

      # @ return [String] A human-readable representation of the chart.
      def to_s
        result = +''
        sets.each_with_index do |a_set, i|
          result << "State[#{i}]\n"
          a_set.entries.each do |item|
            result << "  #{item}\n"
          end
        end

        result
      end

      private

      def add_entry_set
         @sets << ParseEntrySet.new
      end
    end # class
  end # module
end # module

# End of file
