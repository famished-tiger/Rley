# frozen_string_literal: true

require_relative 'calc_lexer'
require_relative 'calc_ast_builder'

def print_title(aTitle)
  puts aTitle
  puts '=' * aTitle.size
end

def print_tree(aTitle, aParseTree)
  # Let's create a parse tree visitor
  visitor = Rley::ParseTreeVisitor.new(aParseTree)

  # Now output formatted parse tree
  print_title(aTitle)
  renderer = Rley::Formatter::Asciitree.new($stdout)
  renderer.render(visitor)
  puts ''
end

# Parse the input expression in command-line
if ARGV.empty?
  my_name = File.basename(__FILE__)
  msg = <<-END_MSG
Demo calculator that prints:
- The Concrete and Abstract Syntax Trees of the math expression.
- The result of the math expression.

Command-line syntax:
  ruby #{my_name} "arithmetic expression"
  where:
    the arithmetic expression is enclosed between double quotes (")

  Examples:
  ruby #{my_name} "2 * 3 + (1 + 3 ** 2)"
  ruby #{my_name} "cos(PI/2) + sqrt(1 + 1)"
END_MSG
  puts msg
  exit(1)
end
puts ARGV[0]

# Create a Rley facade object
engine = Rley::Engine.new

########################################
# Step 1. Load a grammar for calculator
require_relative 'calc_grammar'
engine.use_grammar(CalcGrammar)

lexer = CalcLexer.new(ARGV[0])
result = engine.parse(lexer.tokens)

unless result.success?
  # Stop if the parse failed...
  puts "Parsing of '#{ARGV[0]}' failed"
  puts "Reason: #{result.failure_reason.message}"
  exit(1)
end


# Generate a concrete syntax parse tree from the parse result
cst_ptree = engine.convert(result)
print_tree('Concrete Syntax Tree (CST)', cst_ptree)

# Generate an abstract syntax parse tree from the parse result
engine.configuration.repr_builder = CalcASTBuilder
ast_ptree = engine.convert(result)
print_tree('Abstract Syntax Tree (AST)', ast_ptree)

# Now perform the computation of math expression
root = ast_ptree.root
print_title('Result:')
puts root.interpret.to_s # Output the expression result
# End of file
