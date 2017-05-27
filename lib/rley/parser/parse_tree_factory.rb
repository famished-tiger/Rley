require_relative 'parse_walker_factory'
require_relative 'parse_tree_builder'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Utility class that helps to create a ParseTree from
    # a given Parsing object.
    class ParseTreeFactory
      # Link to Parsing object (= results of recognizer)
      attr_reader(:parsing)


      def initialize(aParsingResult)
        @parsing = aParsingResult
      end

      # Factory that produces the parse tree
      def build_parse_tree()
        a_walker = walker(parsing)
        a_builder = builder(parsing)

        begin
          loop do
            event = a_walker.next
            # puts "EVENT #{event[0]} #{event[1]}"
            a_builder.receive_event(*event)
          end
        rescue StopIteration
          # Do nothing
        end

        return a_builder.tree
      end


      private

      # Create a Parsing walker, that is, an object
      # that will iterate over the relevant nodes (= parsing entries)
      # of a GFGParsing
      def walker(aParseResult)
        walker_factory = ParseWalkerFactory.new
        accept_entry = aParseResult.accepting_entry
        accept_index = aParseResult.chart.last_index
        walker_factory.build_walker(accept_entry, accept_index)
      end

      # Create a Builder, that is, an object
      # that will create piece by piece the forest
      def builder(aParseResult)
        ParseTreeBuilder.new(aParseResult.tokens)
      end
    end # class
  end # module
end # module

# End of file
