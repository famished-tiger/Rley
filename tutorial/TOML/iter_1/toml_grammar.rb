# frozen_string_literal: true

# Grammar for TOML configuration file format
require 'rley' # Load the Rley gem


########################################
# Iteration 1: define a grammar for an initial limited subset of TOML
# Objective: the grammar should support key-value pair of basic string values.
# Names of grammar elements are based on the official TOML grammar
# [TOML v.1.0.0 grammar](https://github.com/toml-lang/toml/blob/1.0.0/toml.abnf)
# @example
#   # This is a TOML document
#
#   title = "TOML Example"
#   quote = "To be or not to be"
#   enabled = true
builder = Rley::grammar_builder do
  # Define first the terminal symbols...
  add_terminals('UNQUOTED-KEY', 'EQUAL', 'STRING')
  add_terminals('BOOLEAN')

  # ... then with syntax rules
  # First found rule is considered to be the top-level rule
  rule 'toml' => 'expr-list'
  rule 'expr-list' => 'expr-list expression'
  rule 'expr-list' => ''
  rule 'expression' => 'keyval'
  rule 'keyval' => 'key EQUAL val'
  rule 'key' => 'UNQUOTED-KEY'
  rule 'val' => 'STRING'
  rule 'val' => 'BOOLEAN'
end

# Let's build a TOML grammar object
TOMLGrammar = builder.grammar
