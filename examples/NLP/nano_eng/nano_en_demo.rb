require 'rley' # Load Rley library

########################################
# Step 0. Instantiate facade object of Rley library.
# It provides a unified, higher-level interface
engine = Rley::Engine.new

########################################
# Step 1. Define a grammar for a nano English-like language
# based on example from Jurafski & Martin book (chapter 8 of the book).
# Bird, Steven, Edward Loper and Ewan Klein: "Speech and Language Processing";
# 2009, Pearson Education, Inc., ISBN 978-0135041963
# It defines the syntax of a sentence in a mini English-like language
# with a very simplified syntax and vocabulary
engine.build_grammar do
  # Next 2 lines we define the terminal symbols
  # (= word categories in the lexicon)
  add_terminals('Noun', 'Proper-Noun', 'Pronoun', 'Verb')
  add_terminals('Aux', 'Determiner', 'Preposition')

  # Here we define the productions (= grammar rules)
  rule 'Start' => 'S'
  rule 'S' => %w[NP VP]
  rule 'S' => %w[Aux NP VP]
  rule 'S' => 'VP'
  rule 'NP' => 'Pronoun'
  rule 'NP' => 'Proper-Noun'
  rule 'NP' => %w[Determiner Nominal]
  rule 'Nominal' => %[Noun]
  rule 'Nominal' => %[Nominal Noun]
  rule 'VP' => 'Verb'
  rule 'VP' => %w[Verb NP]
  rule 'VP' => %w[Verb NP PP]
  rule 'VP' => %w[Verb PP]
  rule 'VP' => %w[VP PP]
  rule 'PP' => %w[Preposition NP]
end

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
}.freeze

########################################
# Step 3. Creating a tokenizer
# A tokenizer reads the input string and converts it into a sequence of tokens
# Highly simplified tokenizer implementation.
def tokenizer(aTextToParse)
  tokens = aTextToParse.scan(/\S+/).map do |word|
    term_name = Lexicon[word]
    raise StandardError, "Word '#{word}' not found in lexicon" if term_name.nil?
    Rley::Lexical::Token.new(word, term_name)
  end

  return tokens
end

########################################
# Step 5. Parsing the input
input_to_parse = 'John saw Mary'
# input_to_parse = 'John saw Mary with a telescope'
# input_to_parse = 'the dog saw a man in the park' # This one is ambiguous
# Convert input text into a sequence of token objects...
tokens = tokenizer(input_to_parse)
result = engine.parse(tokens)

puts "Parsing successful? #{result.success?}"
unless result.success?
  puts result.failure_reason.message
  exit(1)
end

########################################
# Step 6. Generating a parse tree from parse result
ptree = engine.convert(result)

# Let's create a parse tree visitor
visitor = engine.ptree_visitor(ptree)

# Let's create a formatter (i.e. visit event listener)
# renderer = Rley::Formatter::Debug.new($stdout)

# Let's create a formatter that will render the parse tree with characters
renderer = Rley::Formatter::Asciitree.new($stdout)

# Let's create a formatter that will render the parse tree in labelled
# bracket notation
# renderer = Rley::Formatter::BracketNotation.new($stdout)

# Subscribe the formatter to the visitor's event and launch the visit
renderer.render(visitor)
# End of file
