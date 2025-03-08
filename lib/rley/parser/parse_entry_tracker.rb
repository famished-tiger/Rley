# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Helper class that keeps track of the parse entries used
    # while a Parsing instance is constructing a parse forest.
    class ParseEntryTracker
      # The index of the current entry set
      attr_reader(:entry_set_index)

      # The current parse entry
      attr_reader(:parse_entry)

      # The already processed entries from current entry set
      attr_reader(:processed_entries)

      # Constructor.
      def initialize(aEntrySetIndex)
        self.entry_set_index = aEntrySetIndex
      end

      # Write accessor. Sets the value of the entry set index
      def entry_set_index=(anIndex)
        @processed_entries = {}
        @entry_set_index = anIndex
      end

      # Write accessor. Set the given parse entry as the current one.
      def parse_entry=(aParseEntry)
        raise StandardError, 'Nil parse entry' if aParseEntry.nil?

        processed_entries[parse_entry] = true
        @parse_entry = aParseEntry
      end

      # Take the first provided entry that wasn't processed yet.
      def select_entry(theEntrys)
        a_entry = theEntrys.find { |st| !processed_entries.include?(st) }
        self.parse_entry = a_entry
      end

      # The dotted item for the current parse entry.
      def curr_dotted_item
        parse_entry.dotted_rule
      end

      def symbol_on_left
        curr_dotted_item.prev_symbol
      end

      # Notification that one begins with the previous entry set
      def to_prev_entry_set
        self.entry_set_index = entry_set_index - 1
      end
    end # class
  end # module
end # module

# End of file
