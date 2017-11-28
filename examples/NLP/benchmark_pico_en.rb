# File: benchmark_mini_en.rb
# Purpose: benchmark the parse speed
require 'benchmark'
require 'rley' # Load Rley library

# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new do

  add_terminals('Noun', 'Proper-Noun', 'Verb') 
  add_terminals('Determiner', 'Preposition')

  # Here we define the productions (= grammar rules)
  rule 'S' => %w[NP VP]
  rule 'NP' => 'Proper-Noun'
  rule 'NP' => %w[Determiner Noun]
  rule 'NP' => %w[Determiner Noun PP]
  rule 'VP' => %w[Verb NP]
  rule 'VP' => %w[Verb NP PP]
  rule 'PP' => %w[Preposition NP]
end 

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
}.freeze

########################################
# Step 3. Creating a tokenizer
# A tokenizer reads the input string and converts it into a sequence of tokens
# Highly simplified tokenizer implementation.
def tokenizer(aTextToParse, aGrammar)
  tokens = aTextToParse.scan(/\S+/).map do |word|
    term_name = Lexicon[word]
    raise StandardError, "Word '#{word}' not found in lexicon" if term_name.nil?
    terminal = aGrammar.name2symbol[term_name]
    Rley::Lexical::Token.new(word, terminal)
  end
  
  return tokens
end

########################################
# Step 4. Create a parser for that grammar
# Easy with Rley...
parser = Rley::Parser::GFGEarleyParser.new(grammar)

########################################
# Step 5. Parsing the input
input_to_parse = 'John saw Mary with a telescope'

# Convert input text into a sequence of token objects...
tokens = tokenizer(input_to_parse, grammar)

# Use Benchmark mix-in
include Benchmark

bm(6) do |meter|
  meter.report("Parse 100 times") { 100.times { parser.parse(tokens) } }
  meter.report("Parse 1000 times") { 1000.times { parser.parse(tokens) } }
  meter.report("Parse 10000 times") { 10000.times { parser.parse(tokens) } }
  meter.report("Parse 1000000 times") { 100000.times { parser.parse(tokens) } }
end

# puts "Parsing successful? #{result.success?}"
# unless result.success?
  # puts result.failure_reason.message
  # exit(1)
# end