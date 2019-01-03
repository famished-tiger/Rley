require_relative 'cli_options'
require_relative 'json_lexer'
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


# Create a Rley facade object
# If necessary, select AST representation
engine = Rley::Engine.new do |cfg|
  builder = tree_rep == :ast ? JSONASTBuilder : nil
  cfg.repr_builder = builder
end

########################################
# Step 1. Load a grammar for JSON
require_relative 'json_grammar'
engine.use_grammar(GrammarJSON)


input_source = nil
File.open(file_name, 'r') { |f| input_source = f.read }
lexer = JSONLexer.new(input_source)

result = engine.parse(lexer.tokens)

unless result.success?
  # Stop if parse failed...
  puts "Parsing of '#{file_name}' failed"
  puts result.failure_reason.message
  exit(1)
end



# Generate a parse tree from the parse result
ptree = engine.convert(result)

if renderer
  # Let's create a parse tree visitor
  visitor = engine.ptree_visitor(ptree)

  # Now output formatted parse tree
  renderer.render(visitor)
else
  root = ptree.root
  p(root.to_ruby) # Output the Ruby representation of the JSON input
end
# End of file
