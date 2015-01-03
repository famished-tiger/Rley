# Purpose: to demonstrate how to build and render a parse tree for the L0
# language
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
# based on Jurafky & Martin L0 language.
# It defines the syntax of a sentence in a language with a 
# very limited syntax and lexicon in the context of airline reservation.
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('Noun', 'Verb', 'Pronoun', 'Proper-Noun')
builder.add_terminals('Determiner', 'Preposition', )
builder.add_production('S' => %w[NP VP])
builder.add_production('NP' => 'Pronoun')
builder.add_production('NP' => 'Proper-Noun')
builder.add_production('NP' => %w[Determiner Nominal])
builder.add_production('Nominal' => %w[Nominal Noun])
builder.add_production('Nominal' => 'Noun')
builder.add_production('VP' => 'Verb')
builder.add_production('VP' => %w[Verb NP])
builder.add_production('VP' => %w[Verb NP PP])
builder.add_production('VP' => %w[Verb PP])
builder.add_production('PP' => %w[Preposition PP])

# And now build the grammar...
grammar_l0 = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
# This is a very simplistic implementation for demo purposes.

# The lexicon is just a Hash with pairs of the form:
# word =>terminal symbol name
L0_lexicon = {
  'flight' => 'Noun',
  'breeze' => 'Noun',
  'trip' => 'Noun',
  'morning' => 'Noun',
  'is' => 'Verb',
  'prefer' => 'Verb',
  'like' => 'Verb',
  'need' => 'Verb',
  'want' => 'Verb',
  'fly' => 'Verb',
  'me' => 'Pronoun',
  'I' => 'Pronoun',
  'you' => 'Pronoun',
  'it' => 'Pronoun',
  'Alaska' => 'Proper-Noun',
  'Baltimore' => 'Proper-Noun',
  'Chicago' => 'Proper-Noun',
  'United' => 'Proper-Noun',
  'American' => 'Proper-Noun',
  'the' => 'Determiner',
  'a' => 'Determiner',
  'an' => 'Determiner',
  'this' => 'Determiner',
  'these' => 'Determiner',
  'that' => 'Determiner',
  'from' => 'Preposition',
  'to' => 'Preposition',
  'on' => 'Preposition',
  'near' => 'Preposition'
}

# Highly simplified tokenizer implementation.
def tokenizer(aText, aGrammar)
  tokens = aText.scan(/\S+/).map do |word|
    term_name = L0_lexicon[word]
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
parser = Rley::Parser::EarleyParser.new(grammar_l0)

########################################
# Step 3. Tokenize the input
valid_input = 'I prefer a morning flight'
# Another sentence: it is a flight from Chicago
tokens = tokenizer(valid_input, grammar_l0)

########################################
# Step 5. Let the parser process the input
result = parser.parse(tokens)

puts "Parsing success? #{result.success?}"


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