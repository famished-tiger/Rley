# Purpose: define a grammar with left-recursive rule
require 'rley' # Load Rley library

# Instantiate a builder object that will build the grammar for us
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('DOT')
  
  # Grammar with left recursive rule.
	rule 'l_dots' => []
	rule 'l_dots' => %w[l_dots DOT]  
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
result = parser.parse(tokens)

puts "Parsing successful? #{result.success?}"
unless result.success?
  puts result.failure_reason.message
  exit(1)
end