# frozen_string_literal: true

require 'rley'
require_relative 'toml_grammar'
require_relative 'toml_tokenizer'

# Sample TOML document to parse
toml_doc = <<-TOML
  # This is a TOML document

  title = "TOML Example"
  enabled = true
TOML

recognizer = Rley::Parser::GFGEarleyParser.new(TOMLGrammar)
tokenizer = TOMLTokenizer.new(toml_doc)
result = recognizer.parse(tokenizer.tokens)
p result.success?
