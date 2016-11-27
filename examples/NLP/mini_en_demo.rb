require 'rley'  # Load Rley library

########################################
# Step 1. Define a grammar for a micro English-like language
# based on example from NLTK book (chapter 8 of the book).
# Bird, Steven, Edward Loper and Ewan Klein: "Natural Language Processing 
# with Python"; 2009, O’Reilly Media Inc., ISBN 978-0596516499
# It defines the syntax of a sentence in a mini English-like language 
# with a very simplified syntax.

# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new

# Next 2 lines we define the terminal symbols (=word categories in the lexicon)
builder.add_terminals('Noun', 'Proper-Noun', 'Verb') 
builder.add_terminals('Determiner', 'Preposition')

# Here we define the productions (= grammar rules)
builder.add_production('S' => %w[NP VP])
builder.add_production('NP' => 'Proper-Noun')
builder.add_production('NP' => %w[Determiner Noun])
builder.add_production('NP' => %w[Determiner Noun PP])
builder.add_production('VP' => %w[Verb NP])
builder.add_production('VP' => %w[Verb NP PP])
builder.add_production('PP' => %w[Preposition NP])

# And now, let's build the grammar...
grammar = builder.grammar

########################################
# Step 2. Creating a lexicon
# To simplify things, lexicon is implemented as a Hash with pairs of the form:
# word => terminal symbol name
Lexicon = {
  'man' => 'Noun',
  'dog' => 'Noun',
  'cat' => 'Noun',
  'telescope' => 'Noun',
  'park' => 'Noun',  
  'saw' => 'Verb',
  'ate' => 'Verb',
  'walked' => 'Verb',
  'John' => 'Proper-Noun',
  'Mary' => 'Proper-Noun',
  'Bob' => 'Proper-Noun',
  'a' => 'Determiner',
  'an' => 'Determiner',
  'the' => 'Determiner',
  'my' => 'Determiner',
  'in' => 'Preposition',
  'on' => 'Preposition',
  'by' => 'Preposition',
  'with' => 'Preposition'
}

########################################
# Step 3. Creating a tokenizer
# A tokenizer reads the input string and converts it into a sequence of tokens
# Highly simplified tokenizer implementation.
def tokenizer(aTextToParse, aGrammar)
  tokens = aTextToParse.scan(/\S+/).map do |word|
    term_name = Lexicon[word]
    if term_name.nil?
      raise StandardError, "Word '#{word}' not found in lexicon"
    end
    terminal = aGrammar.name2symbol[term_name]
    Rley::Parser::Token.new(word, terminal)
  end
  
  return tokens
end

More realistic NLP will will most probably

########################################
# Step 4. Create a parser for that grammar
# Easy with Rley...
parser = Rley::Parser::GFGEarleyParser.new(grammar)

########################################
# Step 5. Parsing the input
input_to_parse = 'John saw Mary with a telescope'
# Convert input text into a sequence of token objects...
tokens = tokenizer(input_to_parse, grammar)
result = parser.parse(tokens)

puts "Parsing successful? #{result.success?}" # => Parsing successful? true

########################################
# Step 6. Generating the parse forest
pforest = result.parse_forest

