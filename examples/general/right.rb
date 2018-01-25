# Purpose: define a grammar with right-recursive rule
require 'rley' # Load Rley library

# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('DOT')
  
  # Grammar with left recursive rule.
	rule 'r_dots' => []
	rule 'r_dots' => %w[DOT r_dots]  
end

# And now, let's build the grammar...
grammar = builder.grammar

# Highly simplified tokenizer implementation.
def tokenizer(aText, aGrammar)
	tokens = aText.scan(/\./).map do |dot|
	  terminal = aGrammar.name2symbol['DOT']
	  Rley::Lexical::Token.new(dot, terminal)
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