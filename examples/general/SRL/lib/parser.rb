# Purpose: to demonstrate how to build and render a parse tree for JSON
# language
require_relative 'tokenizer'
require_relative 'grammar'
module SRL
  # A parser for a subset of Simple Regex Language
  class Parser < Rley::Parser::GFGEarleyParser
    attr_reader(:source_file)

    # Constructor
    def initialize()
      # Builder the Earley parser with the calculator grammar
      super(Grammar)
    end

    def parse_SRL(aText)
      lexer = Tokenizer.new(aText, grammar)
      tokens = lexer.tokens
      result = parse(tokens)

      return result
    end
  end # class
end # module

# End of file
