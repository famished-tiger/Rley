require 'ostruct'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace
    # Utility class used to trace the parsing of a token sequence.
    class ParseTracer
      # The stream where the trace output is sent
      attr_reader(:ostream)

      # The trace level
      attr_reader(:level)

      attr_reader(:lexemes)

      attr_reader(:col_width)

      def initialize(aTraceLevel, anIO, aTokenSequence)
        @level = aTraceLevel <= 0 ? 0 : [aTraceLevel, 2].min
        @ostream = anIO
        @lexemes = aTokenSequence.map(&:lexeme)

        emit_tokens
        emit_heading
      end

      # Emit the trace text to the output IO
      # if the given trace level is equal or greater to the
      # trace level of the tracer instance.
      def print_if(aLevel, text)
        ostream.print(text) if level >= aLevel
      end

      # Emit the trace of a scanning step.
      def trace_scanning(aStatesetIndex, aParseState)
        return unless level

        scan_picture = '[' + '-' * (col_width - 1) + ']'
        org = OpenStruct.new(origin: aStatesetIndex - 1, 
                             dotted_rule: aParseState.dotted_rule)
        trace_diagram(aStatesetIndex, org, scan_picture)
      end

      def trace_prediction(aStatesetIndex, aParseState)
        return unless level

        trace_diagram(aStatesetIndex, aParseState, '>')
      end
      
      def trace_completion(aStatesetIndex, aParseState)
        return unless level

        if aStatesetIndex == lexemes.size && aParseState.origin.zero? && 
           aParseState.complete?
          picture = '=' * (col_width * lexemes.size - 1)
        else
          count = col_width * (aStatesetIndex - aParseState.origin) - 1
          picture = '-' * count
        end
        completion_picture = '[' + picture + (aParseState.complete? ? ']' : '>')
        trace_diagram(aStatesetIndex, aParseState, completion_picture)
      end

      private

      def emit_tokens()
        literals = lexemes.map { |lx| "'#{lx}'" }
        print_if 1, '[' + literals.join(', ') + "]\n"
      end

      def emit_heading()
        longest = lexemes.map(&:length).max
        @col_width = longest + 3
        headers = lexemes.map { |l| l.center(col_width - 1, ' ').to_s }
        print_if 1, '|.' + headers.join('.') + ".|\n"
      end

      def padding(aStatesetIndex, aParseState, aPicture)
        l_pad_pattern = '.' + ' ' * (col_width - 1)
        left_padding =  l_pad_pattern * [0, aParseState.origin].max
        r_pad_pattern = ' ' * (col_width - 1) + '.'
        right_padding = r_pad_pattern * (lexemes.size - aStatesetIndex)
        return left_padding + aPicture + right_padding
      end

      def parse_state_str(aStatesetIndex, aParseState)
        "[#{aParseState.origin}:#{aStatesetIndex}] #{aParseState.dotted_rule}"
      end

      def trace_diagram(aStatesetIndex, aParseState, aPicture)
        diagram = padding(aStatesetIndex, aParseState, aPicture)
        prefix = '|'
        suffix = '| ' + parse_state_str(aStatesetIndex, aParseState)
        trace = prefix + diagram + suffix

        print_if 1, trace + "\n"
      end
    end # class
  end # module
end # module

# End of file
