module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Abstract class for grammar symbols.
    # A grammar symbol is an element that appears in grammar rules.
    class GrmSymbol
      # The name of the grammar symbol
      attr_reader(:name)

      # An indicator that tells whether the grammar symbol can generate a
      # non-empty string of terminals.
      attr_writer(:generative)

      # Constructor.
      # aName [String] The name of the grammar symbol.
      def initialize(aName)
        @name = aName.dup
      end

      # The String representation of the grammar symbol
      # @return [String]
      def to_s()
        return name.to_s
      end

      # @return [Boolean] true iff the symbol is a terminal
      def terminal?()
        # Default implementation to override if necessary
        return false
      end

      # @return [Boolean] true iff the symbol is generative.
      def generative?()
        return @generative
      end
    end # class
  end # module
end # module

# End of file
