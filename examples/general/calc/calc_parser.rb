# Purpose: to demonstrate how to build and render a parse tree for JSON
# language
require_relative 'calc_lexer'
require_relative 'calc_grammar'

# A parser for arithmetic expressions
class CalcParser < Rley::Parser::GFGEarleyParser
  attr_reader(:source_file)

  # Constructor
  def initialize()
    # Builder the Earley parser with the calculator grammar
    super(CalcGrammar)
  end

  def parse_expression(aText)
    lexer = CalcLexer.new(aText, grammar)
    result = parse(lexer.tokens)

    return result
  end
end # class

# End of file
