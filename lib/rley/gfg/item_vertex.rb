require_relative 'vertex'

module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # TODO: modify definition
    # Represents a specialized vertex in a grammar flow graph 
    # that is associated to a given dotted item.
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class ItemVertex < Vertex
        attr_reader :dotted_item
      
      def initialize(aDottedItem)
        super()
        @dotted_item = aDottedItem
      end
      
      def label()
        return "#{dotted_item}"
      end

    end # class
  end # module
end # module

# End of file