# frozen_string_literal: true

# Grammar for JSON data representation
require 'rley' # Load the gem


########################################
# Define a grammar for JSON
# Original JSON grammar is available at: http://www.json.org/fatfree.html
# Official JSON grammar:  http://rfc7159.net/rfc7159#rfc.section.2
# Names of grammar elements are based on the RFC 7159 documentation
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('false', 'null', 'true') # Literal names
  add_terminals('string', 'number')
  add_terminals('begin-object', 'end-object') # For '{', '}' delimiters
  add_terminals('begin-array', 'end-array') # For '[', ']' delimiters
  add_terminals('name-separator', 'value-separator') # For ':', ',' separators
  rule 'JSON_text' => 'value'
  rule 'value' => 'false'
  rule 'value' => 'null'
  rule 'value' => 'true'
  rule 'value' => 'object'
  rule 'value' => 'array'
  rule 'value' => 'number'
  rule 'value' => 'string'
  rule 'object' => %w[begin-object member-list end-object]
  rule 'object' => %w[begin-object end-object]
  # Next rule is an example of a left recursive rule
  rule 'member-list' => %w[member-list value-separator member]
  rule 'member-list' => 'member'
  rule 'member' => %w[string name-separator value]
  rule 'array' => %w[begin-array array-items end-array]
  rule 'array' => %w[begin-array end-array]
  rule 'array-items' => %w[array-items value-separator value]
  rule 'array-items' => %w[value]
end

# And now build the JSON grammar...
GrammarJSON = builder.grammar
