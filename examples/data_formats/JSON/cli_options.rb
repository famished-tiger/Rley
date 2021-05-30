# frozen_string_literal: true

require 'optparse'

# A Hash specialization that collects the command-line options
class CLIOptions < Hash
  # labelled square notation (LBN).
  # Use online tools (e.g. http://yohasebe.com/rsyntaxtree/) to visualize
  # parse trees from LBN output.
  def initialize(progName, progVersion, args)
    super()

    # Default values
    self[:prog_name] = progName
    self[:prog_version] = progVersion
    self[:format] = :ascii_tree
    self[:rep] = :cst

    options = build_option_parser
    options.parse!(args)
  end

  private

  def build_option_parser
    OptionParser.new do |opts|
      opts.banner = <<-END_BANNER
#{self[:prog_name]}: a demo utility that parses a JSON file
and renders its parse tree to the standard output
in the format specified in the command-line.

Usage: json_demo.rb [options] FILE

Examples:
json_demo --format ascii_tree sample01.json
json_demo --rep ast --format ruby sample01.json
END_BANNER

      opts.separator ''

      format_help = <<-END_TEXT
Select the output format (default: ascii_tree). Available formats:
        ascii_tree  [cst, ast] Simple text representation of parse trees
        minify      [cst] Strip all unnecessary whitespace in input json file
        labelled    [cst, ast] Labelled square notation (LBN)
                    Use online tools (e.g. http://yohasebe.com/rsyntaxtree/)
                    to visualize parse trees from LBN output.
        ruby        [ast] A Ruby representation of the JSON input.
END_TEXT
      formats = %i[ascii_tree labelled minify ruby]
      opts.on('-f', '--format FORMAT', formats, format_help) do |frm|
        self[:format] = frm
      end
      opts.separator ''

      rep_help = <<-END_TEXT
Set the parse tree representation (default: cst)
        cst         Concrete Syntax Tree. The out-of-the-box parse tree
                    representation.
        ast         Abstract Syntaxt Tree. A customized parse tree for JSON.
                    It is a more compact and practical representation.
END_TEXT
      representations = %i[cst ast]
      opts.on('-r', '--rep REP', representations, rep_help) do |rep|
        self[:rep] = rep
      end

      opts.separator ''
      opts.separator '  **** Utility ****'

      opts.on('-v', '--version', 'Display the program version.') do
        puts self[:prog_version]
        exit
      end

      # No argument, shows at tail.  This will print an options summary.
      opts.on_tail('-h', '--help', 'Display this help message.') do
        puts opts
        exit
      end
    end
  end
end # class
