# frozen_string_literal: true

require_relative 'base_formatter'


module Rley # This module is used as a namespace
  # Namespace dedicated to parse tree formatters.
  module Formatter
    # A formatter class that renders the visit notification events
    # from a parse tree visitor
    class Debug < BaseFormatter
      # Current indentation level
      attr_reader(:indentation)

      # Constructor.
      # @param anIO [IO] The output stream to which the rendered grammar
      # is written.
      def initialize(anIO)
        super(anIO)
        @indentation = 0
      end
      
      # Indicates that this formatter accepts all visit events
      # provided their names start with 'before_' or 'after_'
      # @return [Boolean]
      def accept_all
        return true
      end
      
      # Ghost method pattern.
      def method_missing(mth, *args)    
        mth_name = mth.to_s         
        case mth_name
          when /^before_/
            output_event(mth_name, indentation)
            indent unless mth_name == 'before_terminal'
          when /^after_/
            dedent unless mth_name == 'after_terminal'
            output_event(mth_name, indentation)
          else
            super(mth, args)
        end
      end

      private

      def indent()
        @indentation += 1
      end

      def dedent()
        @indentation -= 1
      end

      def output_event(anEvent, indentationLevel)
        output.puts "#{' ' * 2 * indentationLevel}#{anEvent}"
      end
    end # class
  end # module
end # module

# End of file
