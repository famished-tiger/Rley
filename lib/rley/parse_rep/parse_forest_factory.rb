# frozen_string_literal: true

require_relative 'parse_rep_creator'
require_relative 'parse_forest_builder'

module Rley # This module is used as a namespace
  module ParseRep # This module is used as a namespace
    # Utility class that helps to create a ParseForest from
    # a given Parsing object.
    class ParseForestFactory < ParseRepCreator
      protected

      # Create a Builder, that is, an object
      # that will create piece by piece the forest
      def builder(aParseResult, _builder = nil)
        ParseForestBuilder.new(aParseResult.tokens)
      end
      
      # When an end vertex is re-visited then jump
      # its corresponding start vertex. This behaviour
      # makes sense for sharing nodes.
      def jump_to_start()
        true
      end       
    end # class
  end # module
end # module

# End of file
