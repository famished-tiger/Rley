# Purpose: to demonstrate how to build and render a parse tree for JSON
# language
require 'rley' # Load the Rley gem
require_relative 'json_lexer'

# Steps to render a parse tree (of a valid parsed input):
# 1. Define a grammar
# 2. Create a parser for that grammar
# 3. Tokenize the input
# 4. Let the parser process the input
# 5. Generate a parse tree from the parse result
# 6. Render the parse tree (in JSON)

########################################
# Step 1. Load a grammar for JSON
require_relative 'json_grammar'

# A JSON parser derived from our general Earley parser.
class JSONParser < Rley::Parser::GFGEarleyParser
  attr_reader(:source_file)

  # Constructor
  def initialize()
    # Builder the Earley parser with the JSON grammar
    super(GrammarJSON)
  end
  
  def parse_file(aFilename)
    tokens = tokenize_file(aFilename)
    result = parse(tokens)

    return result
  end
  
  private
  
  def tokenize_file(aFilename)
    input_source = nil
    File.open(aFilename, 'r') { |f| input_source = f.read }

    lexer = JSONLexer.new(input_source, GrammarJSON)
    return lexer.tokens
  end
end # class

# End of file
