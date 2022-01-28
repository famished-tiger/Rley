# frozen_string_literal: true

require_relative 'grm_symbol' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A terminal symbol represents a class of words in the language
    # defined the grammar.
    class Terminal < GrmSymbol
      # An indicator that tells whether the grammar symbol can generate a
      # non-empty string of terminals.
      # @return [TrueClass]
      def generative?
        true
      end

      # Return true iff the symbol is a terminal
      # @return [TrueClass]
      def terminal?
        true
      end

      # @return [false] Return true if the symbol derives
      # the empty string. As terminal symbol corresponds to a input token
      # it is by definition non-nullable.
      # @return [FalseClass]
      def nullable?
        false
      end

      # Return a readable text representation of the instance
      # @return [String] The symbol name
      def to_s
        name
      end
    end # class
  end # module
end # module

# End of file
