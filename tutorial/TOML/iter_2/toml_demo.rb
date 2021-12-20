# frozen_string_literal: true

require_relative 'toml_parser'

# Sample TOML document to parse
toml_doc = <<-TOML
  # This is a TOML document

  title = "TOML Example"

  [owner]
  name = "Thomas O'Malley"
  
  [database]
  enabled = true
  ports = [ 8000, 8001, 8002 ]
  data = [ ["delta", "phi"], [3.14] ]
TOML

parser = TOMLParser.new
ptree = parser.parse(toml_doc)

# Let's create a parse tree visitor
visitor = parser.engine.ptree_visitor(ptree)

# Let's create a formatter that will render the parse tree with characters
renderer = Rley::Formatter::Asciitree.new($stdout)

# Subscribe the formatter to the visitor's event and launch the visit
renderer.render(visitor)