require_relative '../syntax/grammar'
require_relative 'dotted_item'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace

    class Token
      attr_reader(:lexeme)
      attr_reader(:terminal)

      def initialize(theLexeme, aTerminal)
        @lexeme = theLexeme
        @terminal = aTerminal
      end

    end # class

  end # module
end # module

# End of file
