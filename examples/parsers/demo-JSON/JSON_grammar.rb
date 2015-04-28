# Purpose: to demonstrate how to build and render a parse tree for JSON
# language
require 'rley'  # Load the gem


########################################
# Define a grammar for JSON
builder = Rley::Syntax::GrammarBuilder.new
builder.add_terminals('KEYWORD') # For true, false, null keywords
builder.add_terminals('JSON_STRING', 'JSON_NUMBER')
builder.add_terminals('LACCOL', 'RACCOL') # For '{', '}' delimiters
builder.add_terminals('LBRACKET', 'RBRACKET') # For '[', ']' delimiters
builder.add_terminals('COLON', 'COMMA') # For ':', ',' separators
builder.add_production('json_text' => 'json_value')
builder.add_production('json_value' => 'json_object')
builder.add_production('json_value' => 'json_array')
builder.add_production('json_value' => 'JSON_STRING')
builder.add_production('json_value' => 'JSON_NUMBER')
builder.add_production('json_value' => 'KEYWORD')
builder.add_production('json_object' => %w[LACCOL json_pairs RACCOL])
builder.add_production('json_object' => ['LACCOL', 'RACCOL'])
builder.add_production('json_pairs' => %w[json_pairs COMMA single_pair])
builder.add_production('json_pairs' => 'single_pair')
builder.add_production('single_pair' => %w[JSON_STRING COLON json_value])
builder.add_production('json_array' => %w[LBRACKET array_items RBRACKET])
builder.add_production('json_array' => ['RBRACKET', 'RBRACKET'])
builder.add_production('array_items' => %w[array_items COMMA json_value])
builder.add_production('array_items' => %w[json_value])

# And now build the grammar...
GrammarJSON = builder.grammar