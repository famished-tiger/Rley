module Rley # This module is used as a namespace
  module Tokens # This module is used as a namespace
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
