# Grammar for JSON data representation
require 'rley'  # Load the gem


########################################
# Define a grammar for JSON
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('KEYWORD') # For true, false, null keywords
  add_terminals('JSON_STRING', 'JSON_NUMBER')
  add_terminals('LACCOL', 'RACCOL') # For '{', '}' delimiters
  add_terminals('LBRACKET', 'RBRACKET') # For '[', ']' delimiters
  add_terminals('COLON', 'COMMA') # For ':', ',' separators
  rule 'json_text' => 'json_value'
  rule 'json_value' => 'json_object'
  rule 'json_value' => 'json_array'
  rule 'json_value' => 'JSON_STRING'
  rule 'json_value' => 'JSON_NUMBER'
  rule 'json_value' => 'KEYWORD'
  rule 'json_object' => %w(LACCOL json_pairs RACCOL)
  rule 'json_object' => %w(LACCOL RACCOL)
  rule 'json_pairs' => %w(json_pairs COMMA single_pair)
  rule 'json_pairs' => 'single_pair'
  rule 'single_pair' => %w(JSON_STRING COLON json_value)
  rule 'json_array' => %w(LBRACKET array_items RBRACKET)
  rule 'json_array' => %w(LBRACKET RBRACKET)
  rule 'array_items' => %w(array_items COMMA json_value)
  rule 'array_items' => %w(json_value)
end

# And now build the grammar...
GrammarJSON = builder.grammar