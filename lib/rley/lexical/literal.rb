# frozen_string_literal: true

require_relative 'token'

module Rley # This module is used as a namespace
  module Lexical # This module is used as a namespace
    # A literal (value) is a token that represents a data value in the parsed
    # language. For instance, in Ruby data values such as strings, numbers,
    # regular expression,... can appear directly in the source code. These are
    # examples of literal values. One responsibility of a tokenizer/lexer is
    # to convert the text representation into a corresponding value in a
    # convenient format for the interpreter/compiler.
    class Literal < Token
      # @return [Object] The value expressed in one of the target datatype.
      attr_reader(:value)

      # Constructor.
      # @param aValue [Object] value of the token in internal representation
      # @param theLexeme [String] the lexeme (= piece of text from input)
      # @param aTerminal [Syntax::Terminal, String]
      # @param aPosition [Rley::Lexical::Position] line, column position pf token
      def initialize(aValue, theLexeme, aTerminal, aPosition = nil)
        super(theLexeme, aTerminal, aPosition)
        @value = aValue
      end
    end # class
  end # module
end # module
# End of file
