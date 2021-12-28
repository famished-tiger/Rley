# frozen_string_literal: true

# Grammar for TOML configuration file format
require 'rley' # Load the Rley gem

########################################
# Iteration 3: define a grammar for a limited subset of TOML
# Objective: the grammar should support key-value pair of basic string values.
# Names of grammar elements are based on the official TOML grammar
# [TOML v.1.0.0 grammar](https://github.com/toml-lang/toml/blob/1.0.0/toml.abnf )
# @example
#   # This is a TOML document
#
#   title = "TOML Example"
#
#   [owner]
#   name = "Tom Preston-Werner"
#   dob = 1979-05-27T07:32:00-08:00
#
#   [database]
#   enabled = true
#   ports = [ 8000, 8001, 8002 ]
#   data = [ ["delta", "phi"], [3.14] ]
#   temp_targets = { cpu = 79.5, case = 72.0 }
#
#   [servers]
#
#   [servers.alpha]
#   ip = "10.0.0.1"
#   role = "frontend"
#
#   [servers.beta]
#   ip = "10.0.0.2"
#   role = "backend"
builder = Rley::grammar_builder do
  # Define first the terminal symbols...
  add_terminals('COMMA', 'DOT', 'EQUAL', 'LBRACKET', 'RBRACKET', 'LACCOLADE', 'RACCOLADE')
  add_terminals('STRING', 'BOOLEAN', 'FLOAT', 'INTEGER')
  add_terminals('OFFSET-DATE-TIME', 'LOCAL-DATE-TIME', 'LOCAL-DATE', 'LOCAL-TIME')
  add_terminals('QUOTED-KEY', 'UNQUOTED-KEY')

  # ... then with syntax rules
  # Reminder: first found rule is considered to be the top-level rule
  rule 'toml' => 'expr-list'

  rule 'expr-list' => 'expr-list expression'
  rule 'expr-list' => ''
  rule 'expression' => 'keyval'
  rule 'expression' => 'table'
  rule 'keyval' => 'key EQUAL val'
  rule 'key' => 'simple-key'
  rule 'key' => 'dotted-key'
  rule 'simple-key' => 'QUOTED-KEY'
  rule 'simple-key' => 'UNQUOTED-KEY'
  rule 'dotted-key' => 'key DOT simple-key'
  rule 'val' => 'STRING'
  rule 'val' => 'BOOLEAN'
  rule 'val' => 'array'
  rule 'val' => 'inline-table'
  rule 'val' => 'FLOAT'
  rule 'val' => 'INTEGER'
  rule 'val' => 'date-time'
  rule 'array' => 'LBRACKET array-values RBRACKET'
  rule 'array' => 'LBRACKET array-values COMMA RBRACKET'
  rule 'array-values' => 'array-values COMMA val'
  rule 'array-values' => 'val'
  rule 'date-time' => 'OFFSET-DATE-TIME'
  rule 'date-time' => 'LOCAL-DATE-TIME'
  rule 'date-time' => 'LOCAL-DATE'
  rule 'date-time' => 'LOCAL-TIME'
  rule 'table' => 'std-table'
  rule 'table' => 'array-table'
  rule 'std-table' => 'LBRACKET key RBRACKET'
  rule 'inline-table' => 'LACCOLADE inline-table-keyvals RACCOLADE'
  rule 'inline-table-keyvals' => 'inline-table-keyvals COMMA keyval'
  rule 'inline-table-keyvals' => 'keyval'
  rule 'array-table' => 'LBRACKET LBRACKET key RBRACKET RBRACKET'
end

# Let's build a TOML grammar object
TOMLGrammar = builder.grammar
