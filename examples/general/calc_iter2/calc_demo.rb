require_relative 'calc_parser'
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

# Create a calculator parser object
parser = CalcParser.new

# Parse the input expression in command-line
if ARGV.empty?
  my_name = File.basename(__FILE__)
  msg = <<-END_MSG
Demo calculator that prints:
- The Concrete and Abstract Syntax Trees of the math expression.
- The result of the math expression.

Command-line symtax:
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
result = parser.parse_expression(ARGV[0])

unless result.success?
  # Stop if the parse failed...
  puts "Parsing of '#{ARGV[0]}' failed"
  puts "Reason: #{result.failure_reason.message}"
  exit(1)
end


# Generate a concrete syntax parse tree from the parse result
cst_ptree = result.parse_tree
print_tree('Concrete Syntax Tree (CST)', cst_ptree)

# Generate an abstract syntax parse tree from the parse result
tree_builder = CalcASTBuilder
ast_ptree = result.parse_tree(tree_builder)
print_tree('Abstract Syntax Tree (AST)', ast_ptree)

# Now perform the computation of math expression
root = ast_ptree.root
print_title('Result:')
puts root.interpret.to_s # Output the expression result
# End of file
