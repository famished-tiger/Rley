# Grammar for simple arithmetical expressions
require 'rley' # Load the gem

########################################
# Define a grammar for basic arithmetical expressions
builder = Rley::Syntax::GrammarBuilder.new do
  add_terminals('NUMBER')
  add_terminals('LPAREN', 'RPAREN') # For '(', ')' delimiters
  add_terminals('PLUS', 'MINUS') # For '+', '-' operators
  add_terminals('STAR', 'DIVIDE') # For '*', '/' operators
  rule 'expression' => 'simple_expression'
  rule 'simple_expression' => 'term'
  rule 'simple_expression' => %w[simple_expression add_operator term]
  rule 'term' => 'factor'
  rule 'term' => %w[term mul_operator factor]
  rule 'factor' => 'NUMBER'
  rule 'factor' => %w[LPAREN expression RPAREN]
  rule 'add_operator' => 'PLUS'
  rule 'add_operator' => 'MINUS'  
  rule 'mul_operator' => 'STAR'
  rule 'mul_operator' => 'DIVIDE'   
end

# And now build the grammar...
CalcGrammar = builder.grammar
