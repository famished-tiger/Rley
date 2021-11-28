# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # Abstract class for grammar symbols.
    # A grammar symbol is an element that appears in grammar rules.
    class GrmSymbol
      # @return [String] The name of the grammar symbol
      attr_reader(:name)

      # Constructor.
      # aName [String] The name of the grammar symbol.
      def initialize(aName)
        raise 'Internal error: nil name encountered' if aName.nil?

        @name = aName.dup
        @name.freeze
      end

      # The String representation of the grammar symbol
      # @return [String]
      def to_s
        name.to_s
      end

      # @return [Boolean] true iff the symbol is a terminal
      def terminal?
        # Default implementation to override if necessary
        false
      end

      # @return [Boolean] true iff the symbol is generative.
      def generative?
        @generative
      end
    end # class
  end # module
end # module

# End of file
