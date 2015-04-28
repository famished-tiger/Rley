# Purpose: to demonstrate how to build and render a parse tree for JSON
# language
require 'pp'
require 'rley'  # Load the gem
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
require_relative 'JSON_grammar'

# A JSON parser derived from our general Earley parser.
class JSONParser < Rley::Parser::EarleyParser
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

=begin
########################################
# Step 3. Create a parser for that grammar
# parser = Rley::Parser::EarleyParser.new(GrammarJSON)
parser = JSONParser.new


########################################
# Step 4. Tokenize the input file
file_name = 'sample02.json'
=begin
input_source = nil
File.open(file_name, 'r') { |f| input_source = f.read }

lexer = JSONLexer.new(input_source, GrammarJSON)
tokens =  lexer.tokens
#=end

########################################
# Step 5. Let the parser process the input
result = parser.parse_file(file_name) # parser.parse(tokens)
unless result.success?
  puts "Parsing of '#{file_name}' failed"
  exit(1)
end

########################################
# Step 6. Generate a parse tree from the parse result
ptree = result.parse_tree

########################################
# Step 7. Render the parse tree (in JSON)
# Let's create a parse tree visitor
visitor = Rley::ParseTreeVisitor.new(ptree)

#Here we create a renderer object...
renderer = Rley::Formatter::Json.new(STDOUT)

# Now emit the parse tree as JSON on the console output
puts "JSON rendering of the parse tree for '#{file_name}' input:"
renderer.render(visitor)
=end
# End of file
