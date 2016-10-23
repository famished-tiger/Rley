require_relative 'parse_entry'
require_relative 'parse_entry_set'


module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Also called a parse table.
    # It is a Grammar Flow Graph implementation.
    # Assuming that n == number of input tokens,
    # the chart is an array with n + 1 entry sets.
    class GFGChart
      # An array of entry sets (one per input token + 1)
      attr_reader(:sets)

      # The level of trace details reported on stdout during the parse.
      # The possible values are:
      # 0: No trace output (default case)
      # 1: Show trace of scanning and completion rules
      # 2: Same as of 1 with the addition of the prediction rules
      attr_reader(:tracer)

      # @param tokenCount [Fixnum] The number of lexemes in the input to parse.
      # @param aTracer [ParseTracer] A tracer object.
      def initialize(tokenCount, aGFGraph, aTracer)
        @tracer = aTracer
        @sets = Array.new(tokenCount + 1) { |_| ParseEntrySet.new }
        push_entry(aGFGraph.start_vertex, 0, 0, :start_rule)
      end

      # The dotted item/rule used to seed the parse chart.
      # It corresponds to the start production and a dot placed
      # at the beginning of the rhs
      # def start_dotted_rule()
        # return self[0].entries.first.dotted_rule
      # end

      # Return the start (non-terminal) symbol of the grammar.
      def start_symbol()
        return sets.first.entries[0].vertex.non_terminal
      end

      # Access the entry set at given position
      def [](index)
        return sets[index]
      end

      # Return the index value of the last non-empty entry set.
      def last_index()
        first_empty = sets.find_index(&:empty?)
        if first_empty.nil?
          index = sets.size - 1
        else
          index = (first_empty == 0) ? 0 : first_empty - 1
        end

        return index
      end

      # Push a parse entry for the chart entry with given index
      def push_entry(aVertex, anOrigin, anIndex, aReason)
        new_entry = ParseEntry.new(aVertex, anOrigin)
        pushed = self[anIndex].push_entry(new_entry)
        if pushed == new_entry && tracer.level > 0
          case aReason
            when :start_rule, :prediction
              tracer.trace_prediction(anIndex, new_entry)

            when :scanning
               tracer.trace_scanning(anIndex, new_entry)

            when :completion
               tracer.trace_completion(anIndex, new_entry)
            else
              fail NotImplementedError, "Unknown push_entry mode #{aReason}"
          end
        end

        return pushed
      end

      # Retrieve the first parse entry added to this chart
      def initial_entry()
        return sets[0].first
      end

      # Retrieve the entry that corresponds to a complete and successful parse
      def accepting_entry()
        # Success can be detected as follows:
        # The last chart entry set has at least one complete parse entry
        # for the start symbol with an origin == 0

        # Retrieve all the end entries (i.e. of the form
        last_entries = sets[last_index].entries.select(&:end_entry?)

        # ... now find the end vertex for start symbol and with origin at zero...
        success_entries = last_entries.select do |entry|
          entry.origin == 0 && entry.vertex.non_terminal == start_symbol
        end

        return success_entries.first
      end
    end # class
  end # module
end # module

# End of file
