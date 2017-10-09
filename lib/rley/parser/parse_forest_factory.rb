require_relative 'parse_rep_creator'
require_relative 'parse_forest_builder'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Utility class that helps to create a ParseForest from
    # a given Parsing object.
    class ParseForestFactory < ParseRepCreator
      protected

      # Create a Builder, that is, an object
      # that will create piece by piece the forest
      def builder(aParseResult, _builder = nil)
        ParseForestBuilder.new(aParseResult.tokens)
      end
    end # class
  end # module
end # module

# End of file
