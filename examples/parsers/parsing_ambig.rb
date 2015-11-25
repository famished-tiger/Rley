# Purpose: to demonstrate how to build and render a parse tree

require 'pp' # TODO remove this dependency
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
# Step 1. Define a grammar for a very simple language
# Grammar 3: An ambiguous arithmetic expression language
# (based on example in article on Earley's algorithm in Wikipedia)
# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('integer', '+', '*')
builder.add_production('P' => 'S')
builder.add_production('S' => %w(S + S))
builder.add_production('S' => %w(S * S))
builder.add_production('S' => 'L')
builder.add_production('L' => 'integer')

# And now build the grammar...
grammar_amb = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
def tokenizer(aText, aGrammar)
  tokens = aText.scan(/\S+/).map do |lexeme|
    case lexeme
      when '+', '*'
        terminal = aGrammar.name2symbol[lexeme]
      when /^[-+]?\d+$/
        terminal = aGrammar.name2symbol['integer']
      else
        msg = "Unknown input text '#{lexeme}'"
        fail StandardError, msg
    end
    Rley::Parser::Token.new(lexeme, terminal)
  end

  return tokens
end

########################################
# Step 3. Create a parser for that grammar
parser = Rley::Parser::EarleyParser.new(grammar_amb)

########################################
# Step 3. Tokenize the input
valid_input = '2 + 3 * 4'
tokens = tokenizer(valid_input, grammar_amb)

########################################
# Step 5. Let the parser process the input
result = parser.parse(tokens)
puts "Parsing success? #{result.success?}"
puts "Ambiguous parse? #{result.ambiguous?}"
# pp result

result.chart.state_sets.each_with_index do |aStateSet, index|
  puts "State[#{index}]"
  puts "========"
  aStateSet.states.each { |aState| puts aState.to_s }
end

=begin
########################################
# Step 6. Generate a parse tree from the parse result
ptree = result.parse_tree
pp ptree

########################################
# Step 7. Render the parse tree (in JSON)
# Let's create a parse tree visitor
visitor = Rley::ParseTreeVisitor.new(ptree)

#Here we create a renderer object...
renderer = Rley::Formatter::Json.new(STDOUT)

# Now emit the parse tree as JSON on the console output
puts "JSON rendering of the parse tree for '#{valid_input}' input:"
renderer.render(visitor)
=end
# End of file