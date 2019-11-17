# frozen_string_literal: true

module Rley # This module is used as a namespace
  module Lexical # This module is used as a namespace
    # A Position is the location of a lexeme within a source file.
    Position = Struct.new(:line, :column) do
      def to_s
        "line #{line}, column #{column}"
      end
    end


    # In Rley, a (lexical) token is an object created by a lexer (tokenizer)
    # and passed to the parser. Such token an object is created when a lexer
    # detects that a sequence of characters(a lexeme) from the input stream
    # is an instance of a terminal grammar symbol.
    # Say, that in a particular language, the lexeme 'foo' is an occurrence
    # of the terminal symbol IDENTIFIER. Then the lexer will return a Token
    # object that states the fact that 'foo' is indeed an IDENTIFIER. Basically,
    # a Token is a pair (lexeme, terminal): it asserts that a given lexeme
    # is an instance of given terminal symbol.
    class Token
      # The sequence of character(s) from the input stream that is an occurrence
      # of the related terminal symbol.
      # @return [String] Input substring that is an instance of the terminal.
      attr_reader(:lexeme)

      # @return [String] The name of terminal symbol matching the lexeme.
      attr_reader(:terminal)

      # @return [Position] The position of the lexeme in the source file.
      attr_reader(:position)

      # Constructor.
      # @param theLexeme [String] the lexeme (= piece of text from input)
      # @param aTerminal [Syntax::Terminal, String]
      #   The terminal symbol corresponding to the lexeme.
      def initialize(theLexeme, aTerminal, aPosition)
        raise 'Internal error: nil terminal symbol detected' if aTerminal.nil?

        @lexeme = theLexeme
        @terminal = aTerminal
        @position = aPosition
      end
    end # class
  end # module
end # module
# End of file
