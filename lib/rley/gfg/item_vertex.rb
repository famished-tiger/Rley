require_relative '../syntax/non_terminal'
require_relative 'vertex'


module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # TODO: modify definition
    # Represents a specialized vertex in a grammar flow graph
    # that is associated to a given dotted item.
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class ItemVertex < Vertex
        # Link to the dotted item object
        attr_reader :dotted_item

        # Optional link to a "shortcut" edge.
        # Applicable only if the dotted expects a non-terminal symbol.
        attr_reader :shortcut

      def initialize(aDottedItem)
        super()
        @dotted_item = aDottedItem
      end
      
      # Set the "shortcut" edge.
      def shortcut=(aShortcut)
        unless aShortcut.kind_of?(ShortcutEdge)
          fail StandardError, 'Invalid shortcut argument'
        end
=begin
        unless next_symbol && next_symbol.kind_of?(Syntax::NonTerminal)
          fail StandardError, 'Invalid shortcut usage'
        end
        
        shortcut_d_item = aShortcut.successor.dotted_item
        unless (dotted_item.production == shortcut_d_item.production) &&
          (dotted_item.position == shortcut_d_item.prev_position)
          fail StandardError, 'Shortcut refers to wrong vertex'
        end
=end        
        @shortcut = aShortcut
      end

      def label()
        return "#{dotted_item}"
      end

      # Returns true if the dotted item has a dot at the end of the production.
      def complete?()
        return dotted_item.reduce_item?
      end

      # Return the symbol before the dot else nil.
      def prev_symbol()
        return dotted_item.prev_symbol
      end      
      
      # Return the symbol after the dot else nil.
      def next_symbol()
        return dotted_item.next_symbol
      end
      
      # Return the non-terminal symbol at the left-hand side of the production
      def lhs()
        return dotted_item.lhs
      end

    end # class
  end # module
end # module

# End of file