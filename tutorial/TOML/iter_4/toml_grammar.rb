# frozen_string_literal: true

# Grammar for TOML configuration file format
require 'rley' # Load the Rley gem

########################################
# Iteration 4: define a grammar for a limited subset of TOML
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
  rule('toml' => 'expression*').tag 'toml'

  rule 'expression' => 'keyval'
  rule('expression' => 'table').tag 'table_expr'
  rule('keyval' => 'key EQUAL val').tag 'keyval'
  rule('key' => 'simple-key')
  rule('key' => 'dotted-key').tag 'dotted_key'
  rule('simple-key' => 'QUOTED-KEY').tag 'atomic_literal'
  rule('simple-key' => 'UNQUOTED-KEY').tag 'atomic_literal'
  rule('dotted-key' => 'key DOT simple-key').tag 'dkey_items'
  rule('val' => 'STRING').tag 'atomic_literal'
  rule('val' => 'BOOLEAN').tag 'atomic_literal'
  rule 'val' => 'array'
  rule 'val' => 'inline-table'
  rule('val' => 'FLOAT').tag 'atomic_literal'
  rule('val' => 'INTEGER').tag 'atomic_literal'
  rule('val' => 'date-time').tag 'atomic_literal'
  rule('array' => 'LBRACKET array-values COMMA? RBRACKET').tag 'array'
  rule('array-values' => 'val (COMMA val)*').tag 'comma_separated'
  rule 'date-time' => 'OFFSET-DATE-TIME'
  rule 'date-time' => 'LOCAL-DATE-TIME'
  rule 'date-time' => 'LOCAL-DATE'
  rule 'date-time' => 'LOCAL-TIME'
  rule 'table' => 'std-table'
  rule 'table' => 'array-table'
  rule('std-table' => 'LBRACKET key RBRACKET').tag 'std_table'
  rule('inline-table' => 'LACCOLADE inline-table-keyvals RACCOLADE').tag 'inline_table'
  rule('inline-table-keyvals' => 'keyval (COMMA keyval)*').tag 'comma_separated'
  rule 'array-table' => 'LBRACKET LBRACKET key RBRACKET RBRACKET'
end

# Let's build a TOML grammar object
TOMLGrammar = builder.grammar.freeze
