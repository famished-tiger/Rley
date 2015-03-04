# Purpose: to demonstrate how to parse an emblematic ambiguous sentence
# Based on example found at: http://www.nltk.org/book_1ed/ch08.html

require 'pp'
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
# Step 1. Define a grammar for a micro English-like language
# based on Jurafky & Martin L0 language (chapter 12 of the book).
# It defines the syntax of a sentence in a language with a 
# very limited syntax and lexicon in the context of airline reservation.
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('N', 'V', 'Pro')  # N(oun), V(erb), Pro(noun)
builder.add_terminals('Det', 'P')       # Det(erminer), P(reposition)
builder.add_production('S' => %w[NP VP])
builder.add_production('NP' => %w[Det N])
builder.add_production('NP' => %w[Det N PP])
builder.add_production('NP' => 'Pro')
builder.add_production('VP' => %w[V NP])
builder.add_production('VP' => %w[VP PP])
builder.add_production('PP' => %w[P NP])

# And now build the grammar...
groucho_grammar = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
# This is a very simplistic implementation for demo purposes.

# The lexicon is just a Hash with pairs of the form:
# word => terminal symbol name
Groucho_lexicon = {
  'elephant' => 'N',
  'pajamas' => 'N',
  'shot' => 'V',
  'I' => 'Pro',
  'an' => 'Det',
  'my' => 'Det',
  'in' => 'P',
}

# Highly simplified tokenizer implementation.
def tokenizer(aText, aGrammar)
  tokens = aText.scan(/\S+/).map do |word|
    term_name = Groucho_lexicon[word]
    if term_name.nil?
      fail StandardError, "Word '#{word}' not found in lexicon"
    end
    terminal = aGrammar.name2symbol[term_name]
    Rley::Parser::Token.new(word, terminal)
  end
  
  return tokens
end

########################################
# Step 3. Create a parser for that grammar
parser = Rley::Parser::EarleyParser.new(groucho_grammar)

########################################
# Step 3. Tokenize the input
valid_input = 'I shot an elephant in my pajamas'
tokens = tokenizer(valid_input, groucho_grammar)

########################################
# Step 5. Let the parser process the input
result = parser.parse(tokens)

puts "Parsing success? #{result.success?}"

#=begin
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
#=end
# End of file