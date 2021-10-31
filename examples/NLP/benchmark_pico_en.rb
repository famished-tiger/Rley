# frozen_string_literal: true

# File: benchmark_pico_en.rb
# Purpose: benchmark the parse speed
require 'benchmark'
require 'rley' # Load Rley library

########################################
# Step 0. Instantiate facade object of Rley library.
# It provides a unified, higher-level interface
engine = Rley::Engine.new

########################################
# Step 1. Define a grammar for a pico English-like language
# based on example from NLTK book (chapter 8 of the book).
# Bird, Steven, Edward Loper and Ewan Klein: "Natural Language Processing
# with Python"; 2009, O’Reilly Media Inc., ISBN 978-0596516499
# It defines the syntax of a sentence in a mini English-like language
# with a very simplified syntax and vocabulary
engine.build_grammar do
  # Next 2 lines we define the terminal symbols
  # (= word categories in the lexicon)
  add_terminals('Noun', 'Proper-Noun', 'Verb')
  add_terminals('Determiner', 'Preposition')

  # Here we define the productions (= grammar rules)
  rule 'S' => 'NP VP'
  rule 'NP' => 'Proper-Noun'
  rule 'NP' => 'Determiner Noun'
  rule 'NP' => 'Determiner Noun PP'
  rule 'VP' => 'Verb NP'
  rule 'VP' => 'Verb NP PP'
  rule 'PP' => 'Preposition NP'
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
# Step 3. Create a tokenizer
# A tokenizer reads the input string and converts it into a sequence of tokens.
# Rley doesn't provide tokenizer functionality.
# (Highly simplified tokenizer implementation).
def tokenizer(aTextToParse)
  offset = -1
  tokens = aTextToParse.scan(/\S+/).map do |word|
    term_name = Lexicon[word]
    raise StandardError, "Word '#{word}' not found in lexicon" if term_name.nil?

    pos = Rley::Lexical::Position.new(1, offset + 1)
    offset += word.length
    Rley::Lexical::Token.new(word, term_name, pos)
  end

  return tokens
end


########################################
# Step 4. Parse the input
input_to_parse = 'John saw Mary with a telescope'
# input_to_parse = 'the dog saw a man in the park' # This one is ambiguous
# Convert input text into a sequence of token objects...
tokens = tokenizer(input_to_parse)

Benchmark.bm(6) do |meter|
  meter.report('Parse 100 times') { 100.times { engine.parse(tokens) } }
  meter.report('Parse 1000 times') { 1000.times { engine.parse(tokens) } }
  meter.report('Parse 10000 times') { 10000.times { engine.parse(tokens) } }
  meter.report('Parse 1000000 times') { 100000.times { engine.parse(tokens) } }
end
