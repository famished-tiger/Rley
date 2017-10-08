require_relative 'cli_options'
require_relative 'json_parser'
require_relative 'json_minifier'
require_relative 'json_ast_builder'

prog_name = 'json_demo'
prog_version = '0.3.0'

cli_options = CLIOptions.new(prog_name, prog_version, ARGV)
if ARGV.empty?
  puts 'Missing input file name.'
  puts 'Use -h option for command-line help.'
  exit(1)
end

file_name = ARGV[0]
# Create a JSON parser object
parser = JSONParser.new 
result = parser.parse_file(file_name) # result object contains parse details

unless result.success?
  # Stop if parse failed...
  puts "Parsing of '#{file_name}' failed"
  puts result.failure_reason.message
  exit(1)
end

tree_rep = cli_options[:rep]
renderer = nil

# Select the output format
case cli_options[:format]
  when :ascii_tree
    renderer = Rley::Formatter::Asciitree.new($stdout)
  when :labelled
    renderer = Rley::Formatter::BracketNotation.new($stdout)
  when :minify
    msg = "minify format works for 'cst' representation only"
    raise StandardError, msg if tree_rep == :ast
    renderer = JSONMinifier.new($stdout)
  when :ruby
    msg = "ruby format works for 'ast' representation only"
    raise StandardError, msg if tree_rep == :cst
end

tree_builder = (tree_rep == :ast)? JSONASTBuilder : nil

# Generate a parse tree from the parse result
ptree = result.parse_tree(tree_builder)

if renderer
  # Let's create a parse tree visitor
  visitor = Rley::ParseTreeVisitor.new(ptree)

  # Now output formatted parse tree
  renderer.render(visitor)
else
  root = ptree.root
  p(root.to_ruby) # Output the Ruby representation of the JSON input
end
# End of file
