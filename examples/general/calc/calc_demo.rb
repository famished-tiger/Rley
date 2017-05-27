require_relative 'calc_parser'

# Create a calculator parser object
parser = CalcParser.new

# Parse the input expression in command-line
if ARGV.empty?
  msg = <<-END_MSG
Command-line symtax:
  ruby #{__FILE__} "arithmetic expression"
  where:
    the arithmetic expression is enclosed between double quotes (")

  Example:
  ruby #{__FILE__} "2 * 3 + (4 - 1)"
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

# Generate a parse tree from the parse result
ptree = result.parse_tree

# Let's create a parse tree visitor
visitor = Rley::ParseTreeVisitor.new(ptree)

# Now output formatted parse tree
renderer = Rley::Formatter::Asciitree.new($stdout)
renderer.render(visitor)
# End of file
