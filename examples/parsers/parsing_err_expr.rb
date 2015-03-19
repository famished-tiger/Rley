# Purpose: to demonstrate how to catch parsing errors

require 'pp' # TODO remove this dependency
require 'rley'  # Load the gem

# Steps to render a parse tree (of a valid parsed input):
# 1. Define a grammar
# 2. Create a tokenizer for the language
# 3. Create a parser for that grammar
# 4. Tokenize the input
# 5. Let the parser process the invalid input


########################################
# Step 1. Define a grammar for a very simple arithmetic expression language
# (based on example in article on Earley's algorithm in Wikipedia)

# Let's create the grammar piece by piece
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('+', '*', 'integer')
builder.add_production('P' => 'S')
builder.add_production('S' => %w(S + M))
builder.add_production('S' => 'M')
builder.add_production('M' => %w(M * T))
builder.add_production('M' => 'T')
builder.add_production('T' => 'integer')

# And now build the grammar...
grammar_s_expr = builder.grammar


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
parser = Rley::Parser::EarleyParser.new(grammar_s_expr)

########################################
# Step 4. Tokenize the invalid input
invalid_input = '2 + 3 * * 4' # Notice the repeated stars (*)
puts "Invalid expression to parse: #{invalid_input}"
puts ''
tokens = tokenizer(invalid_input, grammar_s_expr)

########################################
# Step 5. Let catch the exception caused by a syntax error...
# ... and display the error message
begin
  parser.parse(tokens)
  rescue StandardError => exc
    puts exc.message
end



# End of file