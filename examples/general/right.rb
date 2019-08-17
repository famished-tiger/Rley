# frozen_string_literal: true

# Purpose: define a grammar with right-recursive rule
require 'rley' # Load Rley library

# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new do
  # The grammar defines a language that consists in a sequence
  # of 0 or more dots...
  add_terminals('DOT')
  
  # Grammar with right recursive rule.
  rule 'r_dots' => []
  rule 'r_dots' => %w[DOT r_dots]  
end

# And now, let's build the grammar...
grammar = builder.grammar

# Highly simplified tokenizer implementation.
def tokenizer(aText, aGrammar)
  index = 0
  tokens = aText.scan(/\./).map do |dot|
    terminal = aGrammar.name2symbol['DOT']
    index += 1
    pos = Rley::Lexical::Position.new(1, index)
    Rley::Lexical::Token.new(dot, terminal, pos)
  end

  return tokens
end

input_to_parse = '.' * 500 # Input = 500 consecutive dots

parser = Rley::Parser::GFGEarleyParser.new(grammar)
tokens = tokenizer(input_to_parse, grammar)
result = parser.parse(tokens) # Takes about 20 seconds on my computer!!!!

puts "Parsing successful? #{result.success?}"
unless result.success?
  puts result.failure_reason.message
  exit(1)
end
