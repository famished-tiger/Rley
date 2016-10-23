require_relative 'parse_walker_factory'
require_relative 'parse_forest_builder'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Utility class that helps to create a ParseForest from
    # a given Parsing object.
    class ParseForestFactory
      # Link to Parsing object (= results of recognizer)
      attr_reader(:parsing)


      def initialize(aParsingResult)
        @parsing = aParsingResult
      end
        
      # Factory that produces the parse forest
      def build_parse_forest()
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

        return a_builder.forest
      end


private
      # Create a Parsing walker, that is, an object
      # that will iterate over the relevant nodes (= parsing entries)
      # of a GFGParsing
      def walker(aParseResult)
        walker_factory = ParseWalkerFactory.new
        accept_entry = aParseResult.accepting_entry
        accept_index = aParseResult.chart.last_index        
        walker = walker_factory.build_walker(accept_entry, accept_index)
      end

      # Create a Builder, that is, an object
      # that will create piece by piece the forest
      def builder(aParseResult)
        ParseForestBuilder.new(aParseResult.tokens)
      end
    end # class
  end # module
end # module

# End of file