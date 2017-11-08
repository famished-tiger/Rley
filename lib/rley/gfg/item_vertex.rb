require_relative '../syntax/non_terminal'
require_relative 'vertex'


module Rley # This module is used as a namespace
  module GFG # This module is used as a namespace
    # Specialization of Vertex class. Represents a 
    # vertex in a grammar flow graph associated to a given dotted item.
    # Responsibilities (in addition to inherited ones):
    # - Know its related non-terminal symbol
    class ItemVertex < Vertex
      # Link to the dotted item object
      # @return [DottedItem] The corresponding dotted item      
      attr_reader :dotted_item

      # Optional link to a "shortcut" edge.
      # Applicable only if the dotted expects a non-terminal symbol.
      # @return [ShortcutEdge] Optional "shortcut" edge
      attr_reader :shortcut

      # Constructor.
      # @param aDottedItem [DottedItem] the corresponding dotted item.
      def initialize(aDottedItem)
        super()
        @dotted_item = aDottedItem
      end

      # Set the "shortcut" edge.
      # @param aShortcut [ShortcutEdge] the "shortcut" edge.
      def shortcut=(aShortcut)
        unless aShortcut.kind_of?(ShortcutEdge)
          raise StandardError, 'Invalid shortcut argument'
        end
=begin
        unless next_symbol && next_symbol.kind_of?(Syntax::NonTerminal)
          raise StandardError, 'Invalid shortcut usage'
        end

        shortcut_d_item = aShortcut.successor.dotted_item
        unless (dotted_item.production == shortcut_d_item.production) &&
          (dotted_item.position == shortcut_d_item.prev_position)
          raise StandardError, 'Shortcut refers to wrong vertex'
        end
=end
        @shortcut = aShortcut
      end

      # The label of this vertex.
      # It is the same as the label of the corresponding dotted item.
      # @return [String] Label for this vertex
      def label()
        return dotted_item.to_s
      end

      # Returns true if the dotted item has a dot at the end of the production.
      # @return [Boolean]
      def complete?()
        return dotted_item.reduce_item?
      end

      # Return the symbol before the dot.
      # @return [Syntax::GrmSymbol, NilClass] Previous symbol otherwise nil.
      def prev_symbol()
        return dotted_item.prev_symbol
      end

      # Return the symbol after the dot.
      # @return [Syntax::GrmSymbol, NilClass] Next grammar symbol otherwise nil.      
      def next_symbol()
        return dotted_item.next_symbol
      end

      # Return the non-terminal symbol at the left-hand side of the production
      # @return [Syntax::GrmSymbol] The non-terminal symbol at left side of production.
      def lhs()
        return dotted_item.lhs
      end
    end # class
  end # module
end # module

# End of file
