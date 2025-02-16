# frozen_string_literal: true

require_relative 'toml_parser'
require_relative 'toml_ast_visitor'
require_relative 'toml_2_ruby'

class TOML2RubyConverter
  attr_reader :interpreter

  def convert_file(aFilename)
    if File.exist?(aFilename)
      valid_fname = aFilename
    end

    raise ScriptError, "No such file -- #{aFilename}" unless valid_fname

    source_code = File.read(valid_fname)
    ast_tree = parse_input(source_code)
    ast_tree2ruby(ast_tree)
  end

  private

  def parse_input(toml_doc)
    begin # Rubocop 1.24 behaves oddly
      parser = TOMLParser.new
      parser.parse(toml_doc)
    rescue StandardError => e
      $stderr.puts e.message
      return
    end
  end

  def ast_tree2ruby(ast_tree)
    converter = TOML2Ruby.new
    visitor = TOMLASTVisitor.new(ast_tree)
    converter.convert(visitor)
  end
end # class

agent = TOML2RubyConverter.new

if ARGV.empty?
  puts 'Command line: ruby tom2ruby_demo.rb <TOML file>'
  exit 1
else
 result = agent.convert_file(ARGV[0]) # Parse TOML get its Ruby representation
 puts result
end
