require_relative 'chart'

module Rley # This module is used as a namespace
  module Parser # This module is used as a namespace

    class Parsing
      attr_reader(:chart)
      attr_reader(:tokens)

      def initialize(startDottedRule, theTokens)
        @tokens = theTokens.dup
        @chart = Chart.new(startDottedRule, tokens.size)
      end

    end # class

  end # module
end # module

# End of file