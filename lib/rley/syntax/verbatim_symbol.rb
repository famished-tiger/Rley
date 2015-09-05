require_relative 'terminal' # Load superclass

module Rley # This module is used as a namespace
  module Syntax # This module is used as a namespace
    # A verbatim word is terminal symbol that represents one unique word
    # in the language defined the grammar.
    class VerbatimSymbol < Terminal
      # The exact text representation of the word.
      attr_reader(:text)

      def initialize(aText)
        super(aText) # Do we need to separate the text from the name?
        @text = aText.dup
      end
      
      # The String representation of the verbatim symbol
      # @return [String]
      def to_s()
        return "'#{text}'"
      end
    end # class
  end # module
end # module

# End of file
