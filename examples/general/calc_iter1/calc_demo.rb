require_relative 'calc_parser'
require_relative 'calc_ast_builder'

# Retrieve input expression to parse from command-line
if ARGV.empty?
  my_name = File.basename(__FILE__)
  msg = <<-END_MSG
Command-line symtax:
  ruby #{my_name} "arithmetic expression"
  where:
    the arithmetic expression is enclosed between double quotes (")

  Example:
  ruby #{my_name} "2 * 3 + (1 + 3 ** 2)"
END_MSG
  puts msg
  exit(1)
end

# Create a calculator parser object
parser = CalcParser.new
result = parser.parse_expression(ARGV[0])

unless result.success?
  # Stop if the parse failed...
  puts "Parsing of '#{ARGV[0]}' failed"
  puts "Reason: #{result.failure_reason.message}"
  exit(1)
end

tree_builder = CalcASTBuilder

# Generate a parse tree from the parse result
ptree = result.parse_tree(tree_builder)

root = ptree.root
puts root.interpret # Output the expression result
# End of file
