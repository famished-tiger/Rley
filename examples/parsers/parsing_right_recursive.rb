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
# Step 1. Define a problematic grammar
# Grammar Z: A grammar with hidden left recursion and a cycle
# (based on example in book of D. Grune, C JH. Jacobs,
# "Parsing Techniques: A Practical Guide"
# Springer, ISBN: 978-1-4419-1901-4, (2010) p. 224
# Let's create the grammar step-by-step with the grammar builder:
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('a')
builder.add_production('S' => %w(a S))
builder.add_production('S' => []) # Empty RHS

# And now build the grammar...
right_recursive_gram = builder.grammar


########################################
# 2. Create a tokenizer for the language
# The tokenizer transforms the input into an array of tokens
def tokenizer(aText, aGrammar)
  tokens = aText.chars.map do |lexeme|
    case lexeme
      when 'a'
        terminal = aGrammar.name2symbol[lexeme]
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
parser = Rley::Parser::EarleyParser.new(right_recursive_gram)

########################################
# Step 3. Tokenize the input
valid_input = 'aaaa'
tokens = tokenizer(valid_input, right_recursive_gram)

########################################
# Step 5. Let the parser process the input
result = parser.parse(tokens)
puts "Parsing success? #{result.success?}"
#pp result

result.chart.state_sets.each_with_index do |aStateSet, index|
  puts "State[#{index}]"
  puts "========"
  aStateSet.states.each { |aState| puts aState.to_s }
end

# End of file