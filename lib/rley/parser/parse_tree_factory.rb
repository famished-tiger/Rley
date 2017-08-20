require_relative 'parse_rep_creator'
# require_relative 'parse_tree_builder' # TODO remove this line
require_relative 'cst_builder'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Utility class that helps to create a ParseTree from
    # a given Parsing object.
    class ParseTreeFactory < ParseRepCreator

      protected

      # Create a Builder, that is, an object
      # that will create piece by piece the forest
      def builder(aParseResult)
        CSTBuilder.new(aParseResult.tokens)
      end
    end # class
  end # module
end # module

# End of file
