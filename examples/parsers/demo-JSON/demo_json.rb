require_relative 'JSON_parser'

# Create a JSON parser object
parser = JSONParser.new 

# Parse the input file with name given in command-line
if ARGV.empty?
  msg = <<-END_MSG
Command-line symtax:
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
  exit(1)
end

# Generate a parse tree from the parse result
ptree = result.parse_tree

# Do something with the parse tree: render it on the output console.
# Step a: Let's create a parse tree visitor
visitor = Rley::ParseTreeVisitor.new(ptree)

# Step b: Select the rendition format to be JSON
renderer = Rley::Formatter::Json.new(STDOUT)

# Step c: Now emit the parse tree as JSON on the console output
puts "JSON rendering of the parse tree for '#{file_name}' input:"
renderer.render(visitor)
# End of file
