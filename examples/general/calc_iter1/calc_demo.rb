require_relative 'calc_lexer'
require_relative 'calc_ast_builder'

# Retrieve input expression to parse from command-line
if ARGV.empty?
  my_name = File.basename(__FILE__)
  msg = <<-END_MSG
Command-line syntax:
  ruby #{my_name} "arithmetic expression"
  where:
    the arithmetic expression is enclosed between double quotes (")

  Example:
  ruby #{my_name} "2 * 3 + (1 + 3 * 2)"
END_MSG
  puts msg
  exit(1)
end

# Create a Rley facade object
engine = Rley::Engine.new do |cfg|
  cfg.repr_builder = CalcASTBuilder
end

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


# Generate a parse tree from the parse result
ptree = engine.to_ptree(result)

root = ptree.root
puts root.interpret # Output the expression result
# End of file
