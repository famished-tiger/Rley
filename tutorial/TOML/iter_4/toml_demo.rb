# frozen_string_literal: true

require 'yaml'
require_relative 'toml_parser'

# Sample TOML document to parse
toml_doc = <<-TOML
# This is a TOML document

title = "TOML Example"

# [owner]
# name = "Tom Preston-Werner"
# dob = 1979-05-27T07:32:00-08:00

# [database]
# enabled = true
# ports = [ 8000, 8001, 8002 ]
# data = [ ["delta", "phi"], [3.14] ]
# temp_targets = { cpu = 79.5, case = 72.0 }

# [servers]

# [servers.alpha]
# ip = "10.0.0.1"
# role = "frontend"

# [servers.beta]
# ip = "10.0.0.2"
# role = "backend"
TOML

parser = TOMLParser.new
ptree = parser.parse(toml_doc)

# Let's serialize the parse tree in YAML format
YAML::dump(ptree, $stdout)
