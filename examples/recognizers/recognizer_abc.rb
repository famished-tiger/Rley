# Purpose: to demonstrate how to build a recognizer
# A recognizer is a kind of parser that indicates whether the input
# complies to the grammar or not.

require 'rley'  # Load the gem

# Steps to build a recognizer:
# 1. Define a grammar
# 2. Create a parser for that grammar
# 3. Build the input
# 4. Let the parser process the input
# 5. Check the parser's result to see whether the input was valid (=recognized)

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

# Keep track of the terminal symbols of the grammar:
term_a = grammar_abc.name2symbol['a']
term_b = grammar_abc.name2symbol['b']
term_c = grammar_abc.name2symbol['c']

########################################
# Step 2. Create a parser for that grammar
parser = Rley::Parser::EarleyParser.new(grammar_abc)

########################################
# Step 3. Build the input
# Mimicking the output of a tokenizer
valid_input = [
  Rley::Parser::Token.new('a', term_a),
  Rley::Parser::Token.new('a', term_a),
  Rley::Parser::Token.new('b', term_b),
  Rley::Parser::Token.new('c', term_c),
  Rley::Parser::Token.new('c', term_c)
]

########################################
# Step 4. Let the parser process the input
result = parser.parse(valid_input)


########################################
# Step 5. Check the parser's result to see whether the input was valid
puts "Successful parse of 'aabcc'? #{result.success?}"
# Output: Successful parse of 'aabcc'? true



# Let's redo steps 3, 4, 5 again with an invalid input.
invalid_input = [
  Rley::Parser::Token.new('a', term_a),
  Rley::Parser::Token.new('a', term_a),
  Rley::Parser::Token.new('b', term_b),
  Rley::Parser::Token.new('c', term_c)
]
result = parser.parse(invalid_input)
puts "Successful parse of 'aabc'? #{result.success?}"
# Output: Successful parse of 'aabc'? false

# End of file