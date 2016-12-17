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
  puts result.failure_reason.message
  exit(1)
end

# Generate a parse forest from the parse result
pforest = result.parse_forest
# End of file
