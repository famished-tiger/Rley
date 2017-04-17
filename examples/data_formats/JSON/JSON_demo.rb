require_relative 'JSON_parser'

# Create a JSON parser object
parser = JSONParser.new 

# Parse the input file with name given in command-line
if ARGV.empty?
  msg = <<-END_MSG
A demo utility that converts a JSON file into labelled square notation (LBN).
Use online tools (e.g. http://yohasebe.com/rsyntaxtree/) to visualize 
parse trees from LBN output.

Command-line syntax:

  ruby #{__FILE__} filename
  where:
    filename is the name of a JSON file
    
  Example:
  ruby #{__FILE__} sample01.json
END_MSG
  puts msg
  exit(1)
end
file_name = ARGV[0]
result = parser.parse_file(file_name) # result object contains parse details

unless result.success?
  # Stop if the parse failed...
  puts "Parsing of '#{file_name}' failed"
  puts result.failure_reason.message
  exit(1)
end

# Generate a parse tree from the parse result
ptree = result.parse_tree
require 'yaml'
File.open('json1.yml', 'w') {|f| YAML.dump(ptree, f)}

# Let's create a parse tree visitor
visitor = Rley::ParseTreeVisitor.new(ptree)

# Output the labelled bracket notation of the tree
use_notation = Rley::Formatter::BracketNotation.new($stdout)
use_notation.render(visitor)


# End of file
