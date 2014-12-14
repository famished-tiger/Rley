# Purpose: to demonstrate how to build and render a parse tree

require 'rley'  # Load the gem

# Steps to render a parse tree (of a valid parsed input):
# 1. Define a grammar
# 2. Create a tokenizer for the language
# 3. Create a parser for that grammar
# 4. Tokenize the input
# 5. Let the parser process the input
# 6. Generate a parse tree from the parse result
# 7. Render the parse tree (in JSON)

########################################
# Step 1. Define a grammar for a very simple language
# It recognizes/generates strings like 'b', 'abc', 'aabcc', 'aaabccc',...
# (based on example in N. Wirth's book "Compiler Construction", p. 6)
# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('a', 'b', 'c')
builder.add_production('S' => 'A')
builder.add_production('A' => %w(a A c))
builder.add_production('A' => 'b')

# And now build the grammar...
grammar_abc = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
def tokenizer(aText, aGrammar)
  tokens = aText.chars.map do |ch|
    terminal = aGrammar.name2symbol[ch]
    fail StandardError, "Unknown input character '#{ch}'" if terminal.nil?
    Rley::Parser::Token.new(ch, terminal)
  end
  
  return tokens
end

########################################
# Step 3. Create a parser for that grammar
parser = Rley::Parser::EarleyParser.new(grammar_abc)

########################################
# Step 3. Tokenize the input
valid_input = 'aabcc'
tokens = tokenizer(valid_input, grammar_abc)

########################################
# Step 5. Let the parser process the input
result = parser.parse(tokens)


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
puts "JSON rendering of the parse tree for '#{valid_input}' input:"
renderer.render(visitor)

# End of file