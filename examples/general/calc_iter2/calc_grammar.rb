# frozen_string_literal: true

# Grammar for simple arithmetical expressions
require 'rley' # Load the gem

########################################
# Define a grammar for basic arithmetical expressions
builder = Rley::grammar_builder do
  add_terminals('NUMBER')
  add_terminals('PLUS', 'MINUS') # For '+', '-' operators or sign
  add_terminals('STAR', 'DIVIDE', 'POWER') # For '*', '/', '**' operators
  add_terminals('LPAREN', 'RPAREN') # For '(', ')' delimiters
  add_terminals('PI', 'E') # For numeric constants
  add_terminals('RESERVED') # Reserved identifiers

  rule 'expression' => 'simple_expression'
  rule 'simple_expression' => 'term'
  rule 'simple_expression' => 'simple_expression add_operator term'
  rule 'term' => 'factor'
  rule 'term' => 'term mul_operator factor'
  rule 'factor' => 'simple_factor'
  rule 'factor' => 'factor POWER simple_factor'
  rule 'simple_factor' => 'sign scalar'
  rule 'simple_factor' => 'unary_function in_parenthesis'
  rule 'simple_factor' => 'MINUS in_parenthesis'
  rule 'simple_factor' => 'in_parenthesis'
  rule 'sign' => 'PLUS'
  rule 'sign' => 'MINUS'
  rule 'sign' => []
  rule 'scalar' => 'NUMBER'
  rule 'scalar' => 'PI'
  rule 'scalar' => 'E'
  rule 'unary_function' => 'RESERVED'
  rule 'in_parenthesis' => 'LPAREN expression RPAREN'
  rule 'add_operator' => 'PLUS'
  rule 'add_operator' => 'MINUS'
  rule 'mul_operator' => 'STAR'
  rule 'mul_operator' => 'DIVIDE'
end

# And now build the grammar...
CalcGrammar = builder.grammar
