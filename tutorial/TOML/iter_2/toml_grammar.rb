# frozen_string_literal: true

# Grammar for TOML configuration file format
require 'rley' # Load the Rley gem


########################################
# Iteration 2: define a grammar for a limited subset of TOML
# Objective: the grammar should support key-value pair of basic string values.
# Names of grammar elements are based on the official TOML grammar
# [TOML v.1.0.0 grammar](https://github.com/toml-lang/toml/blob/1.0.0/toml.abnf )
# @example
#   # This is a TOML document
#
#   title = "TOML Example"
#
#   [owner]
#   name = "Thomas O'Malley"
#
#   [database]
#   enabled = true
#   ports = [ 8000, 8001, 8002 ]
#   data = [ ["delta", "phi"], [3.14] ]
builder = Rley::grammar_builder do
  # Define first the terminal symbols...
  add_terminals('COMMA', 'EQUAL', 'LBRACKET', 'RBRACKET')
  add_terminals('STRING', 'BOOLEAN', 'FLOAT', 'INTEGER')
  add_terminals('UNQUOTED-KEY')

  # ... then with syntax rules
  # Reminder: first found rule is considered to be the top-level rule
  rule('toml' => 'expr-list')

  rule('expr-list' => 'expr-list expression')
  rule('expr-list' => '')
  rule('expression' => 'keyval')
  rule('expression' => 'table')
  rule('keyval' => 'key EQUAL val')
  rule('key' => 'UNQUOTED-KEY')
  rule('val' => 'STRING')
  rule('val' => 'BOOLEAN')
  rule('val' => 'array')
  rule('val' => 'FLOAT')
  rule('val' => 'INTEGER')
  rule('array' => 'LBRACKET array-values RBRACKET')
  rule('array' => 'LBRACKET array-values COMMA RBRACKET')
  rule('array-values' => 'array-values COMMA val')
  rule('array-values' => 'val')
  rule('table' => 'std-table')
  rule('std-table' => 'LBRACKET key RBRACKET')
end

# Let's build a TOML grammar object
TOMLGrammar = builder.grammar.freeze
