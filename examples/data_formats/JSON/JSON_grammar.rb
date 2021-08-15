# frozen_string_literal: true

# Grammar for JSON data representation
require 'rley' # Load the gem


########################################
# Define a grammar for JSON
# Original JSON grammar is available at: http://www.json.org/fatfree.html
# Official JSON grammar:  http://rfc7159.net/rfc7159#rfc.section.2
# Names of grammar elements are based on the RFC 7159 documentation
builder = Rley::grammar_builder do
  add_terminals('false', 'null', 'true') # Literal names
  add_terminals('string', 'number')
  add_terminals('begin-object', 'end-object') # For '{', '}' delimiters
  add_terminals('begin-array', 'end-array') # For '[', ']' delimiters
  add_terminals('name-separator', 'value-separator') # For ':', ',' separators

  rule 'JSON_text' => 'value'
  rule 'value' => 'false'
  rule 'value' => 'null'
  rule 'value' => 'true'
  rule 'value' => 'array'
  rule 'value' => 'object'
  rule 'value' => 'number'
  rule 'value' => 'string'
  rule 'object' => 'begin-object member_list? end-object'

  # Next rule is an example of a left recursive rule
  rule 'member_list' => 'member_list value-separator member'
  rule 'member_list' => 'member'
  rule 'member' => 'string name-separator value'
  rule 'array' => 'begin-array array_items? end-array'
  rule 'array_items' => 'array_items value-separator value'
  rule 'array_items' => 'value'
end

# And now build the JSON grammar...
GrammarJSON = builder.grammar
