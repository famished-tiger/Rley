# Purpose: to use a grammar that causes some Earley parsers to fail.
# See: http://stackoverflow.com/questions/22311323/earley-parser-recursion
require 'rley'  # Load the gem

# Steps to parse some valid input:
# 1. Define a grammar
# 2. Create a tokenizer for the language
# 3. Create a parser for that grammar
# 4. Tokenize the input
# 5. Let the parser process the input & trace its progress


########################################
# Step 1. Define a grammar that might cause infinite recursion
# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('ident')
builder.add_production('S' => 'E')
builder.add_production('E' => ['E', 'E'] )
builder.add_production('E' => 'ident')

# And now build the grammar...
grammar_tricky = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
def tokenizer(aText, aGrammar)
  terminal = aGrammar.name2symbol['ident']
  
  tokens = aText.chars.map do |ch|
    Rley::Parser::Token.new(ch, terminal)
  end
  
  return tokens
end

########################################
# Step 3. Create a parser for that grammar
parser = Rley::Parser::EarleyParser.new(grammar_tricky)

########################################
# Step 3. Tokenize the input
valid_input = 'abcdefg'
tokens = tokenizer(valid_input, grammar_tricky)

########################################
# Step 5. Let the parser process the input
# Force the parser to trace its parsing progress.
result = parser.parse(tokens, 1)
puts "Parsing success? #{result.success?}"

# End of file