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
END_BANNER

      opts.separator ''

      format_help = <<-END_TEXT
Select the output format (default: ascii_tree). Available formats:
  ascii_tree  Simple text representation of parse trees
  minify      Strip all unnecessary whitespace in the input json file
  labelled    Labelled square notation (LBN)
              Use online tools (e.g. http://yohasebe.com/rsyntaxtree/) 
              to visualize parse trees from LBN output.
END_TEXT
      formats = %i[ascii_tree labelled minify]
      opts.on('-f', '--format FORMAT', formats, format_help) do |frm|
        self[:format] = frm
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
